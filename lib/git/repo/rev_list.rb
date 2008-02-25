require 'git/repo/mixin'

module Git
  # This class is instantiated by Git::Repo#rev_list, and can be iterated
  # through with #each or any Enumerable method.  Most commit limiting and
  # commit ordering options to git-rev-list(1) can be be specified as chained
  # method calls with the dashes changd to underscores, as in the following
  # examples:
  #
  #   repo.rev_list(repo.head).max_count(10).skip(20)
  #   repo.rev_list(:all).before(Time.local(2007)).after(Time.local(2006))
  #   repo.rev_list(repo.head).first_parent.reverse
  class Repo::RevList

    include Git::Repo::Mixin
    include Enumerable
    def initialize(repo, revisions, arguments = []) #:nodoc:
      @repo, @revisions, @arguments = repo, revisions, arguments
    end

    def each
      git.exec("rev-list",*arguments) do |rev|
        yield repo.instantiate_object(rev.chomp, "commit")
      end
    end

    # Read only preview of the arguments intended for git-rev-parse(1)
    def arguments
       @arguments.map do |arg|
        "--#{Array(arg).join("=")}"
      end + @revisions.map {|r| r == :all ? "--all" : r }
    end

    def inspect #:nodoc:
      inspect = "rev_list(#{@revisions.map {|a|a.inspect}.join(",")})"
       @arguments.map do |arg|
         inspect << ".#{Array(arg).first.to_s.sub('-','_')}"
         if Array(arg).size > 1
           inspect << "(" << arg[1..-1].map {|a|a.inspect}.join(",") << ")"
         end
       end
      super(inspect)
    end

    def to_s #:nodoc:
      "git rev-list #{arguments.join(" ")}"
    end

    def clone #:nodoc:
      self.class.new(repo,@revisions.dup,@arguments.dup)
    end

    def reverse! #:nodoc:
      unless @arguments.delete("reverse")
        @arguments << "reverse"
      end
      self
    end

    def reverse #:nodoc:
      clone.reverse!
    end

    %w(since after until before min_age max_age max_count skip).each do |method|
      # TODO: use class_eval(string) to mandate argument
      define_method("#{method}!") do |arg|
        @arguments << [method.sub("_","-")]
        if arg.kind_of?(String)
          @arguments.last << arg
        else
          @arguments.last << Integer(arg)
        end
        self
      end
      define_method(method) do |arg|
        clone.send("#{method}!",arg)
      end
    end

    # Acts as an alias for
    #   max_count(n).to_a.first(n) # integer argument
    #   max_count(1).to_a.first    # no argument
    def first(n = nil)
      if n
        max_count(n).to_a.first(n)
      else
        max_count(1).each {|e| return e}
        nil
      end
    end

    %w(author committer grep).each do |method|
      define_method("#{method}!") do |arg|
        @arguments << [method.sub("_","-")]
        %w(identity tagger author git_regexp source).each do |ident|
          arg = arg.send(ident) if arg.respond_to?(ident)
        end
        @arguments.last << arg.to_s
        self
      end
      define_method(method) do |arg|
        clone.send("#{method}!",arg)
      end
    end

    %w(regexp_ignore_case extended_regexp remove_empty full_history no_merges first_parent cherry_pick merge boundary dense sparse bisect_all topo_order date_order).each do |method|
      define_method("#{method}!") do |arg|
        @arguments << method.sub("_","-")
        self
      end
      define_method(method) do |arg|
        clone.send("#{method}!",arg)
      end
    end

  end
end
