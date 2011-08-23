# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "girth/version"

Gem::Specification.new do |s|
  s.name        = "girth"
  s.version     = Girth::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Tim Pope']
  s.email       = 'ruby@tp0pe.0rg'.gsub(/0/,'o')
  s.homepage    = "http://github.com/tpope/girth"
  s.has_rdoc    = true
  s.summary     = 'Syntactically rich Git library with a bias towards IRB'
  s.description = 'Syntactically rich Git library with a bias towards IRB. Includes a git-irb command.'

  s.rubyforge_project = "girth"

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths      = ["lib"]
  s.add_development_dependency 'minitest'
end
