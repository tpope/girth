require 'open3'
require 'girth/mixin'

module Girth
  class Executor

    include Girth::Mixin

    class Error < Girth::Error
    end

    def self.popen3(*args,&block)
      args.flatten!
      args.map! {|a| a.kind_of?(Symbol) ? a.to_s.tr('-_','_-') : a.to_s}
      Open3.popen3(*args,&block)
    end

    def initialize(repo)
      @repo = repo
    end

    def popen3(*args,&block)
      args.flatten!
      args.map! {|a| a.respond_to?(:sha1) ? a.sha1 : a}
      args.unshift("--git-dir=#{repo.git_dir}")
      if repo.bare?
        args.unshift("--bare")
      else
        args.unshift("--work-tree=#{repo.work_tree}")
      end
      args.unshift("git")
      repo.in_work_tree { self.class.popen3(*args,&block) }
    end

    # Invokes a command.  If the command writes to stderr, said output is
    # raised as an exception.  Otherwise, read from stdout and return it as a
    # string.  If a block is given, each line is yielded to it.
    def exec(*args,&block)
      popen3(*args) do |i,o,e|
        err = e.read
        if err.empty?
          if block_given?
            o.each_line(&block)
            nil
          else
            o.read
          end
        else
          raise Error, err.chomp
        end
      end
    end

    # Call git-rev-parse on a single revision, raising if nothing is found.
    def rev_parse(rev)
      git.exec("rev-parse","--verify",rev).chomp
    end

    # Similar to backticks, but accepts multiple arguments like #system, and
    # raises an error if there is output on stderr.  Mnemonic: %x()
    def self.x(*args)
      Open3.popen3(*args) do |i,o,e|
        errors = e.read
        raise Error, errors.chomp unless errors.empty?
        o.read
      end
    end

    def self.version
      x("git","--version")[/\d[\d.]*\d/]
    end

  end
end
