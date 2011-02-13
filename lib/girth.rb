module Girth

  class Error < ::RuntimeError
  end

  # Initialize a repository at the given path and #open it.
  def self.init(*args, &block)
    Repo.init(*args, &block)
  end

  # Open a repository at a given path.  Optionally yields or instance_evals
  # depending on the presence and arity of the given block.
  def self.open(*args, &block)
    Repo.open(*args, &block)
  end

  class <<self
    alias [] open
  end

  require 'girth/repo'
  require 'girth/executor'
  require 'girth/object'
  require 'girth/ref'
  require 'girth/rev_list'
  autoload :Config, 'girth/config'
  autoload :Identity, 'girth/identity'
  autoload :VERSION, 'girth/version'
end
