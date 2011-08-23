require File.expand_path('../test_helper', __FILE__)

class ExecutorTest < MiniTest::Unit::TestCase

  def setup
    @repo = create_empty_repo
  end

  def test_stderr_should_raise
    assert_raises(Girth::Executor::Error) { @repo.git.exec("show","TAIL") }
  end

  def test_should_have_version
    assert_match /\A\d[\d.]*\d\z/, Girth::Executor.version
  end

end
