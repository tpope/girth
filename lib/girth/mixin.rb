module Girth
  module Mixin

    attr_reader :repo # Overridable
    def repository
      repo
    end

    def git
      repo.git
    end

    def inspect(text = nil)
      repo_inspect = "#{repo.inspect}."
      repo_inspect = "" if repo_inspect == "self."
      repo_inspect << (text || to_s)
    end

  end
end
