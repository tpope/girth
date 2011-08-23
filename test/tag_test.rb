require File.expand_path('../test_helper', __FILE__)

class TagTest < MiniTest::Unit::TestCase

  def setup
    @repo = create_empty_repo
    @repo.git.exec("tag","-a","-m","A tag","a_tag",@repo.head)
    @tag_ref = @repo.refs.tags.a_tag
  end

  def test_should_implicitly_dereference
    assert_kind_of Girth::Ref,    @tag_ref
    assert_kind_of Girth::Tag,    @tag_ref.object
    assert_kind_of Girth::Tag,    @tag_ref.tag
    assert_kind_of Girth::Commit, @tag_ref.commit
    assert_kind_of Girth::Commit, @tag_ref[]
  end

  def test_should_have_metadata
    assert_equal "A tag\n",     @tag_ref.message
    assert_equal "Him",         @tag_ref.tagger.name
    assert_equal "him@him.him", @tag_ref.tagger.email
  end

end
