module Git

  def self.[](dir)
    Repo[dir]
  end

  require 'girth/repo'
  require 'girth/executor'
  require 'girth/object'
  require 'girth/ref'
  require 'girth/rev_list'
  require 'girth/identity'
  require 'girth/config'
  require 'girth/version'
end

