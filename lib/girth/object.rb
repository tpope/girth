require 'girth/mixin'
require 'forwardable'

module Git

  # Abstract base class for Tag, Commit, Tree, and Blob.
  class Repo::Object

    include Git::Repo::Mixin
    extend Forwardable

    def self.parsing_reader(*methods) #:nodoc:
      methods.each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__
          def #{method}
            parse unless defined? @#{method}
            @#{method}
          end
        RUBY
      end
    end

    attr_reader :sha1

    def initialize(repo, sha1) #:nodoc:
      @repo, @sha1 = repo, sha1
    end

    def self.get(repo,hash) #:nodoc:
      repo.instantiate_object(hash)
    end

    alias id sha1
    alias to_s sha1

    def binary_sha1
      @sha1.gsub(/../n) {|x| x.to_i(16).chr}
    end

    # +self+, for duck typing with Git::Reference objects.
    def object
      self
    end

    def type
      self.class.name.split("::").last.downcase
    end

    def inspect #:nodoc:
      if repo.inspect == "self"
        sha1[0,7].inspect.gsub('"','`')+".#{type}"
      else
        super("fetch(#{"#{sha1[0,7]}".inspect}).#{type}")
      end
    end

    # Raw body of the object.
    def raw
      git.exec("cat-file",type,@sha1)
    end

  end

  class Tag < Repo::Object

    alias tag object

    parsing_reader :tagged, :tagger, :name, :message

    def_delegators :tagged, :commit, :tree, :treeish, :blob, :describe, :[], :~, :^

    private
    def parse
      git.popen3("cat-file","tag",@sha1) do |i,o,e|
        object = type = nil
        loop do
          line = o.gets.to_s.chomp
          case line
          when ""                then break
          when /^object (.*)/    then object = $1
          when /^type (.*)/      then type = $1
          when /^tag (.*)/       then @name = $1
          when /^tagger (.*)/    then @tagger = Identity.parse($1)
          else raise "unrecognizable commit line #{line}"
          end
        end
        @message = o.read
        @tagged = repo.instantiate_object(object)
      end
      self
    end

  end

  class Commit < Repo::Object

    alias commit object

    parsing_reader :tree, :author, :committer, :parents, :message
    alias treeish tree

    def_delegators :tree, :[], :/, :entries

    # First parent
    def succ
      parents.first
    end

    # git-describe(1) the commit
    def describe
      git.exec("describe",sha1).chomp
    end

    # git-name-rev(1) the commit
    def name
      output = git.exec("name-rev","--name-only",sha1).chomp
      output == "undefined" ? sha1[0..7] : output
    end

    # First line of commit message.
    def summary
      message[/.*/]
    end

    # Negation of the commit, currently as a simple string
    #
    #   ~commit #=> "^#{commit.sha1}"
    def ~
      "^#{sha1}"
    end

    # The nth parent of the comment, starting with 1.  The special value 0
    # returns +self+.
    def ^(i = 1)
      return self if i.zero?
      parents[i-1]
    end

    # With Integer and Range arguments, acts as if the history is an Array and
    # returns the appropriate commits as with Array#[].  Negative arguments are
    # not supported.
    #
    # Given a Regexp, the first ancestor with a matching message.  The current
    # commit is included.
    #
    # Given a String, tree[string] (like revision:string).
    #
    # With no argument at all, +self+ (like revision^{}).
    def [](index = 0, count = nil)
      case index

      when Integer
        return if count.to_i < 0
        final = self
        index.times do
          return unless final
          final = final.parents.first
        end
        if count
          array = []
          count.to_int.times do
            break if final.nil?
            array << final
            final = final.parents.first
          end
          array
        else
          final
        end

      when Range
        raise ArgumentError, "no count allowed with Range" if count
        final = self
        index.first.times do
          return unless final
          final = final.parents.first
        end
        array = []
        index.each do
          break if final.nil?
          array << final
          final = final.parents.first
        end
        return array

      when Regexp
        raise ArgumentError, "no count allowed with Regexp" if count
        commit = self
        to_be_searched = []
        while commit
          return commit if commit =~ index
          to_be_searched += commit.parents[1..-1]
          commit = commit.parents.first || to_be_searched.shift
        end
        nil

      when String
        raise ArgumentError, "no count allowed with String" if count
        tree[index]

      else
        raise TypeError

      end
    end

    def_delegators :message, :=~

    def +(n = 1) #:nodoc:
      final = self
      n.times do
        final = final.parents.first
        return unless final
      end
      final
    end

    # If commit C has parent P and no clear ancestry relation to N, the
    # following conditions hold:
    #
    #   C < P #=> true       C <= P #=> true
    #   C > P #=> false      C >= P #=> false
    #   P < C #=> false      P <= C #=> false
    #   P > C #=> true       P >= C #=> true
    #   C < N #=> nil        C <= N #=> nil
    #   C > N #=> nil        C >= N #=> nil
    #   N < N #=> false      N <= N #=> true
    #   N > N #=> false      N >= N #=> true
    #
    # Note that for a condition to be true, the sign must point towards the
    # child.
    def <=>(other)
      unless other.kind_of?(Git::Repo::Object) || other.kind_of?(Git::Ref)
        raise TypeError, "#{other.class} and a git object can't be compared", caller
      end
      return 0 if sha1 == other.sha1
      merge_base = git.exec("merge-base",sha1,other.sha1).chomp
      if merge_base == sha1
        return 1
      elsif merge_base == other.sha1
        return -1
      end
    rescue Git::Executor::Error
      return nil
    end

    # merge-base for the given commits
    def &(other)
      repo.instantiate_object(git.exec("merge-base",sha1,other.sha1).chomp,"commit")
    end

    include Comparable

    %w(< > <= >=).each do |operator|
      class_eval <<-RUBY, __FILE__, __LINE__
        def #{operator}(*args)
          super
        rescue ArgumentError
        end
      RUBY
      # define_method(operator) {|other| begin; super; rescue ArgumentError; end}
    end

    private
    def parse
      git.popen3("cat-file","commit",@sha1) do |i,o,e|
        @parents = []
        loop do
          line = o.gets.to_s.chomp
          case line
          when ""                then break
          when /^tree (.*)/      then @tree      =   Tree.new(repo, $1)
          when /^parent (.*)/    then @parents  << Commit.new(repo, $1)
          when /^author (.*)/    then @author    = Identity.parse($1)
          when /^committer (.*)/ then @committer = Identity.parse($1)
          else raise "unrecognizable commit line #{line}"
          end
        end
        @message = o.read
      end
      self
    end

  end

  class Tree < Repo::Object

    include Enumerable

    def entries
      return @entries if @entries
      @entries = []
      git.popen3("cat-file","tree",@sha1) do |i,f,e|
        until f.eof?
          mode = f.readline(" ").to_i(8)
          filename = f.readline("\0")[0..-2]
          hash = f.read(20).unpack("H*").first
          @entries << Entry.new(hash, mode, filename, self)
        end
      end
      @entries
    end

    alias files entries
    def_delegators :entries, :each

    alias tree object
    alias treeish tree

    # Access an entry by name.  Returns +nil+ if no entry by that name exists.
    def [](filename = "")
      filename.split("/").inject(self) do |object, component|
        return unless object.respond_to?(:entries)
        object.files.detect {|file|file.name == component and break file.object}
      end
    end

    alias / []

    # Create and return a new commit for this tree.
    def commit!(message, *parents)
      git.popen3("commit-tree",sha1,*parents.map {|p| ["-p",p]}.flatten) do |i,o,e|
        i.puts message
        i.close
        repo.instantiate_object(o.read.chomp,"commit")
      end
    end

    class Entry

      include Repo::Mixin

      attr_reader :mode, :name, :tree, :sha1

      def initialize(sha1, mode, name, tree = nil)
        @sha1, @mode, @name, @tree = sha1, mode, name, tree
      end

      def repo
        @tree && @tree.repo
      end

      # The SHA1 referenced by this entry.
      def sha1
        @sha1
      end

      # TODO: swap arguments to be consistent
      def inspect #:nodoc:
        if tree
          "%s[(%s;%07o;%s)]" % [tree.inspect,mode,sha1[0,7].inspect,name.inspect]
        else
          "%s.new(%s,%07o,%s)" % [self.class.inspect,sha1[0,7].inspect,mode,name.inspect]
        end
      end

      # The blob or tree referenced by this entry.
      def object
        @object ||= if directory?
                      repo.instantiate_object(@sha1, "tree")
                    else
                      repo.instantiate_object(@sha1, "blob")
                    end
      end

      def symlink?
        @mode[13] != 0
      end

      def directory?
        @mode[14] != 0
      end

      def executable?
        @mode[0] != 0
      end

      def <=>(other)
        return unless other.respond_to?(:tree) && other.tree == tree
        return unless other.respond_to?(:name)
        return name <=> other.name
      end

    end

  end

  class Blob < Repo::Object
    alias [] object # Shorthand to refer to a blob, tree, or commit
    alias blob object
    def body
      git.exec("cat-file","blob",@sha1)
    end
    alias read body
  end

end
