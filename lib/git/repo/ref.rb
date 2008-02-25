require 'git/repo/mixin'
require 'forwardable'

module Git

  # Encapsulates a reference, such as a branch, tag, or HEAD.
  class Ref

    include Git::Repo::Mixin
    extend Forwardable

    def initialize(repo, path) #:nodoc:
      @repo, @path = repo, path
    end

    # SHA1 of the referenced object.
    def sha1
      repo.git.exec("rev-parse","--verify",@path).chomp
    end
    alias id sha1

    # The referenced object.
    def object
      repo.instantiate_object(sha1)
    end

    alias follow object

    def_delegators :object, :==, :succ, :[]

    def reflog
      if File.readable?("#{repo.git_dir}/logs/#{@path}")
        Ref::Log.new(self)
      end
    end

    def inspect #:nodoc:
      if @path =~ /^refs\//
        inspect = "#{repo.inspect}" + @path.split('/').map do |component|
          if component =~ /^[a-z][a-z0-9_]+$/ && !Collection.method_defined?(component)
            ".#{component}"
          else
            "[#{component.inspect}]"
          end
        end.join
        inspect.sub(/\Aself\./,'')
      elsif %w(HEAD ORIG_HEAD).include?(@path)
        super(@path.downcase)
      else
        super("ref(#{@path.inspect})")
      end
    end

    def to_s #:nodoc:
      @path
    end

    protected

    # Delegates to the underlying object.
    def method_missing(method,*args,&block)
      object = object()
      if object.respond_to?(method)
        object.send(method,*args,&block)
      else
        super(method,*args,&block)
      end
    end

    # This represents a "directory" of heads, like "refs/remotes/origin" or
    # "refs/tags".
    class Collection

      include Git::Repo::Mixin
      include Enumerable

      def initialize(repo, path)
        @repo, @path = repo, path
      end

      # Recursively iterate through all contained references.
      def each
        repo.each_ref(@path) do |object, ref|
          yield Git::Ref.new(repo, ref)
        end
      end

      # Fetch a reference or another collection of references.  If there is no
      # reference by the given name, +nil+ is returned.
      def [](name)
        refs = []
        repo.each_ref(path = "#@path/#{name}") do |object, ref|
          return Git::Ref.new(repo, ref) if ref == path
          refs << ref
        end
        return Collection.new(repo, path) if refs.any?
      end

      # Like #[], only raise if the reference cannot be found.
      def method_missing(method,*args,&block)
        if args == [:collection]
          self[method] || Collection.new(repo,method)
        elsif args.empty?
          self[method] or raise Git::Repo::Error, "no such reference #@path/#{method}"
        else
          super(method,*args,&block)
        end
      end

      def inspect #:nodoc:
        inspect = "#{repo.inspect}" + @path.split('/').map do |component|
          if component =~ /^[a-z][a-z0-9_]+$/ && !respond_to?(component)
            ".#{component}"
          else
            "[#{component.inspect}]"
          end
        end.join
        inspect.sub(/\Aself\./,'')
      end

      def to_s #:nodoc:
        "#{@path}/"
      end

    end

    # reflog
    class Log

      include Git::Repo::Mixin
      extend Forwardable
      include Enumerable

      attr_reader :reference

      def initialize(reference) #:nodoc:
        @reference = reference
      end

      def_delegators :reference, :repo

      def inspect #:nodoc:
        "#{@reference.inspect}.reflog"
      end

      def [](index)
        each do |entry|
          return entry if entry.index == index
        end
        nil
      end

      def each
        # Timestamp information doesn't appear to be exposed by any command, so
        # let's parse the log ourselves
        lines = File.readlines("#{repo.git_dir}/logs/#{reference}")
        lines.reverse.each_with_index do |line,index|
          yield Entry.new(self,index,line)
        end
      end

      def_delegators :to_a, :first, :last, :size, :length

      def to_s
        to_a.map {|x| "#{x}\n"}.join
      end

      class Entry
        include Git::Repo::Mixin
        extend Forwardable

        attr_reader :identity, :message, :object, :last, :index, :reflog

        def initialize(log, index, line) #:nodoc:
          @reflog, @index = log, index
          metadata, @message = line.split("\t",2)
          @message.chomp!
          last, object, identity  = metadata.split(" ",3)
          @identity = Git::Identity.parse(identity)
          @object = @reflog.repo.instantiate_object(object,"commit")
          unless last == "0" * 40
            @last = @reflog.repo.instantiate_object(last,"commit")
          end
        end

        def_delegators :object, :commit, :tree, :[]
        def_delegators :reflog, :reference, :repo

        def to_s #:nodoc:
          "#{object.sha1[0,7]}... #{@reflog.reference}@{#@index}: #@message"
        end

        def inspect #:nodoc:
          "#{reflog.inspect}[#{index.inspect}]"
        end

      end

    end

  end

  Repo::Ref = Ref
end
