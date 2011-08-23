require File.expand_path('../test_helper', __FILE__)

class ConfigTest < MiniTest::Unit::TestCase

  def setup
    @repo = create_empty_repo
  end

  def test_should_read_config
    assert_equal "0",   @repo.config.get('core.repositoryformatversion')
    assert_equal "",    @repo.config.get('core.unknownoption')
    assert_equal 0,     @repo.config.get_integer('core.repositoryformatversion')
    assert_nil          @repo.config.get_integer('core.unknownoption')
    assert_equal true,  @repo.config.get_boolean("core.filemode")
    assert_nil          @repo.config.get_boolean("core.unknownoption")
    assert_kind_of Hash,@repo.config.to_h
  end

end
