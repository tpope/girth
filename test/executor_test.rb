require File.dirname(__FILE__) + '/test_helper'

class ExecutorTest < Test::Unit::TestCase

  def setup
    @repo = create_empty_repo
  end

  def test_stderr_should_raise
    assert_nothing_raised                    { @repo.git.exec("diff","HEAD") }
    assert_raise(Git::Repo::Executor::Error) { @repo.git.exec("diff","TAIL") }
  end

  def test_should_have_version
    assert_match /\A\d[\d.]*\d\z/, Git::Repo::Executor.version
  end

end
