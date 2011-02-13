module Git
  class Repo

    class Error < ::RuntimeError
    end

    def self.[](dir)
      new(dir)
    end

    attr_reader :git_dir

    def self.init(dir = nil, bare = false)
      command = %w(git)
      command << "--bare" if bare
      command << "init"
      command << "-q"
      begin
        old_dir = ENV["GIT_DIR"]
        ENV["GIT_DIR"] = nil
        dir ||= old_dir || "."
        Dir.chdir(dir) do
          Open3.popen3(*command) do |i,o,e|
            errors = e.read
            raise Executor::Error, errors, caller unless errors.empty?
          end
        end
      ensure
        ENV["GIT_DIR"] = old_dir
      end
      new(dir)
    end

    def initialize(dir = nil)
      old_dir = ENV["GIT_DIR"]
      ENV["GIT_DIR"] = nil
      @argument = dir || old_dir || "."
      Dir.chdir(@argument) do
        @git_dir = Open3.popen3("git","rev-parse","--git-dir") do |i,o,e|
          o.read.chomp
        end
        raise Error, "fatal: Not a git repository" if @git_dir.to_s.empty?
        if @git_dir == "."
          # Inside the git dir
          failed = 16.times do
            if File.directory?(@git_dir+"/objects") && File.directory?(@git_dir+"/refs") && File.exists?(@git_dir+"/HEAD")
              break false
            end
            @git_dir = File.join("..", @git_dir)
          end
          if failed
            raise Error, "fatal: Not a git repository"
          end
        end
        @git_dir = ::File.join(".",@git_dir) if @git_dir[0] == ?~
        @git_dir = ::File.expand_path(@git_dir)
      end
    ensure
      ENV["GIT_DIR"] = old_dir
    end

    # +self+
    def repo
      self
    end
    alias repository repo

    # The working tree, or +nil+ in a bare repository.
    def work_tree
      if ::File.basename(@git_dir) == ".git"
        ::File.dirname(@git_dir)
      end
    end

    def bare?
      !work_tree
    end

    # Call the block while chdired to the working tree.  In a bare repo, the
    # git dir is used instead.
    def in_work_tree(&block)
      Dir.chdir(work_tree || @git_dir,&block)
    end

    def ref(path)
      ref = Git::Ref.new(self, path)
      if path =~ /^[[:xdigit:]]{40}(\^\{\w+\})?$/
        ref.object
      else
        ref
      end
    end

    def [](path)
      if path =~ /^[[:xdigit:]]{40}$/
        instantiate_object(path)
      elsif path =~ /^([[:xdigit:]]{4,40})(?:\^\{(\w+)\})?$/
        instantiate_object(git.rev_parse(path))
      else
        Git::Ref.new(self, path)
      end
    end

    def fetch(path)
      ref(path).object
    end

    alias object fetch

    def instantiate_object(sha1, type = nil) #:nodoc:
      raise Error, "Full SHA1 required" unless sha1 =~ /^[[:xdigit:]]{40}$/
      type ||= git.exec("cat-file","-t",sha1).chomp
      case type
      when "tag"    then    Git::Tag.new(self,sha1)
      when "commit" then Git::Commit.new(self,sha1)
      when "tree"   then   Git::Tree.new(self,sha1)
      when "blob"   then   Git::Blob.new(self,sha1)
      else raise "unknown type #{type}"
      end
    end

    # Find an object.
    def rev_parse(rev)
      instantiate_object(git.rev_parse(rev))
    end

    alias ` rev_parse

    # HEAD ref
    def head
      ref("HEAD")
    end

    # ORIG_HEAD ref
    def orig_head
      ref("ORIG_HEAD")
    end

    def refs
      @refs ||= Git::Ref::Collection.new(self,"refs")
    end

    def heads
      refs.heads(:collection)
    end

    def remotes
      refs.remotes(:collection)
    end

    def tags
      refs.tags(:collection)
    end

    def inspect
      "#{Git::Repo.inspect}[#{@argument.inspect}]"
    end

    def each_ref(*args)
      pattern = args.empty? ? "refs" : args.join("/")
      git.exec("for-each-ref", "--format=%(objectname) %(refname)", pattern) do |line|
        yield *line.chomp.split(" ",2)
      end
    end

    def rev_list(*args)
      RevList.new(self,args)
    end

    # Runs Git::Repo::Executor::x in the work tree or git dir.
    def x(*args)
      in_work_tree do
        Executor.x(*args)
      end
    end

    def author
      Identity.parse(git.exec("var","GIT_AUTHOR_IDENT"))
    end

    def committer
      Identity.parse(git.exec("var","GIT_COMMITTER_IDENT"))
    end

    def method_missing(method,*args,&block)
      if args.empty?
        [refs,tags,heads,remotes].each do |group|
          ref = group[method] and return ref
        end
      end
      super(method,*args,&block)
    end

    def create(content)
      if content.kind_of?(Hash)
        git.popen3("hash-object","-t","tree","-w","--stdin") do |i,o,e|
          content.sort.each do |filename, object|
            if filename.to_s =~ /[\0\/]/
              raise ArgumentError, "tree filenames can't contain nulls or slashes", caller
            end
            if object.respond_to?(:tree)
              i.write "040000 #{filename}\0#{object.tree.binary_sha1}"
            elsif object.respond_to?(:blob)
              i.write "100644 #{filename}\0#{object.blob.binary_sha1}"
            else
              raise ArgumentError, "trees can only contain trees and blobs", caller
            end

          end
          i.close
          Tree.new(self,o.read.chomp)
        end
      else
        git.popen3("hash-object","-w","--stdin") do |i,o,e|
          if content.respond_to?(:read)
            while hunk = content.read(1024)
              i.write hunk
            end
          else
            i.write(content.to_str)
          end
          i.close
          Blob.new(self,o.read.chomp)
        end
      end
    end

    # Returns a Git::Repo::Config object.
    def config(include_global = true)
      Git::Repo::Config.new(self, include_global)
    end

    # Returns a Git::Repo::Executor object for running commands.
    #
    #   repo.git.exec("status") #=> "...output of git status..."
    def git
      @git ||= Executor.new(self)
    end

  end

  Repository = Repo
end
