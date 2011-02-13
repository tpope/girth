$:.unshift(File.dirname(File.dirname(__FILE__))+'/lib')

require 'girth'
require 'test/unit'
require 'fileutils'
require 'tempfile'

class Test::Unit::TestCase

  def create_empty_repo(directory = nil)
    if directory.nil?
      file = Tempfile.new("girth-test")
      directory = file.path
      file.unlink
    end
    at_exit { FileUtils.rm_rf(directory) }
    FileUtils.mkdir_p(directory)
    repo = Girth.init(directory,true)
    repo.git.exec("config","user.name","Him")
    repo.git.exec("config","user.email","him@him.him")
    blank = repo.create("")
    tree = repo.create(".gitignore" => blank)
    commit = tree.commit!("Initial revision")
    if repo.bare?
      repo.git.exec("update-ref","HEAD",commit.sha1)
    else
      repo.git.exec("merge",commit.sha1)
    end
    repo
  end

end
