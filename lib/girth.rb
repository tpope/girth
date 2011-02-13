module Girth

  class Error < ::RuntimeError
  end

  def self.[](dir)
    Repo[dir]
  end

  def self.init(*args)
    Repo.init(*args)
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
