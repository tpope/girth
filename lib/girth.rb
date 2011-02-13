module Girth

  class Error < ::RuntimeError
  end

  def self.[](*args, &block)
    Repo.send(:[], *args, &block)
  end

  def self.init(*args, &block)
    Repo.init(*args, &block)
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
