begin
  require 'rubygems'
rescue LoadError
end
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
$:.unshift(File.dirname(__FILE__), 'lib')
require 'girth'

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'girth'
PKG_VERSION   = Girth::VERSION::STRING
PKG_FILE_NAME   = "#{PKG_NAME}-#{PKG_VERSION}"

desc "Default task: test"
task :default => [ :test ]


# Run the unit tests
Rake::TestTask.new { |t|
  t.libs << "test"
  t.test_files = Dir['test/*_test.rb']
  t.verbose = true
}


# Generate the RDoc documentation
Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.add('lib')
  rdoc.rdoc_files.add('README.rdoc')
  rdoc.main     = "README.rdoc"
  rdoc.title    = "Girth"
  rdoc.options << '--inline-source'
}


# Create compressed packages
spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY
  s.name = PKG_NAME
  s.summary = 'Syntactically rich Git library with a bias towards IRB'
  s.description = 'Syntactically rich Git library with a bias towards IRB. Includes a git-irb command.'
  s.version = PKG_VERSION

  s.author = 'Tim Pope'
  s.email = 'ruby@tp0pe.0rg'.gsub(/0/,'o')
  s.rubyforge_project = PKG_NAME
  s.homepage = "http://#{PKG_NAME}.rubyforge.org"

  s.has_rdoc = true
  # s.requirements << 'none'
  s.require_path = 'lib'

  s.bindir = "bin"
  s.executables = ["git-irb"]
  s.default_executable = "git-irb"

  s.files = [ "Rakefile", "README.rdoc" ]
  s.files = s.files + Dir.glob( "lib/**/*.rb" )
  s.files = s.files + Dir.glob( "test/**/*" ).reject { |item| item[-1] == ?~ || item.include?( "\.svn" ) }
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |t|
    t.test_files = Dir['test/*_test.rb']
    t.verbose = true
    t.rcov_opts << "--text-report"
    # t.rcov_opts << "--exclude '/(mechanize|hpricot)\\b'"
  end
rescue LoadError
end
