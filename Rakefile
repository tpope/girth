begin
  require 'rubygems'
rescue LoadError
end
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'
require 'rake/contrib/rubyforgepublisher'
$:.unshift(File.dirname(__FILE__), 'lib')
require 'git/repo'

PKG_BUILD     = ENV['PKG_BUILD'] ? '.' + ENV['PKG_BUILD'] : ''
PKG_NAME      = 'git-repo'
PKG_VERSION   = Git::Repo::VERSION::STRING
PKG_FILE_NAME   = "#{PKG_NAME}-#{PKG_VERSION}"

RUBY_FORGE_PROJECT = PKG_NAME
RUBY_FORGE_USER    = "tpope"

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
  rdoc.rdoc_files.add('README')
  rdoc.main     = "README"
  rdoc.title    = "Git::Repo"
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
  s.rubyforge_project = RUBY_FORGE_PROJECT
  s.homepage = "http://#{PKG_NAME}.rubyforge.org"

  s.has_rdoc = true
  # s.requirements << 'none'
  s.require_path = 'lib'

  s.bindir = "bin"
  s.executables = ["git-irb"]
  s.default_executable = "git-irb"

  s.files = [ "Rakefile" ] #, "README", "setup.rb" ]
  s.files = s.files + Dir.glob( "lib/**/*.rb" )
  s.files = s.files + Dir.glob( "test/**/*" ).reject { |item| item[-1] == ?~ || item.include?( "\.svn" ) }
end

Rake::GemPackageTask.new(spec) do |p|
  p.gem_spec = spec
  p.need_tar = true
  p.need_zip = true
end

# Publish documentation
desc "Publish the API documentation"
task :pdoc => [:rerdoc] do 
  # Rake::RubyForgePublisher.new(RUBY_FORGE_PROJECT,RUBY_FORGE_USER).upload
  Rake::SshDirPublisher.new("rubyforge.org", "/var/www/gforge-projects/#{PKG_NAME}", "doc").upload
end

desc "Publish the release files to RubyForge."
task :release => [ :package ] do
  `rubyforge login`

  for ext in %w( gem tgz zip )
    release_command = "rubyforge add_release #{PKG_NAME} #{PKG_NAME} 'REL #{PKG_VERSION}' pkg/#{PKG_NAME}-#{PKG_VERSION}.#{ext}"
    puts release_command
    system(release_command)
  end
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
