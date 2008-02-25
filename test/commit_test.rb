require File.dirname(__FILE__) + '/test_helper'

class CommitTest < Test::Unit::TestCase

  def setup
    @repo = create_empty_repo
    @head = @repo.head.object
  end

  def test_should_implicitly_dereference
    assert_kind_of Git::Ref,    @repo.head
    assert_kind_of Git::Commit, @repo.head.object
    assert_kind_of Git::Commit, @repo.head.commit
    assert_kind_of Git::Commit, @repo.head[]
    assert_kind_of Git::Blob,   @repo.head[".gitignore"]
  end

  def test_should_index
    commit = @head
    5.times do |i|
      commit = commit.tree.commit!("Commit #{i+1}\n",commit)
    end

    assert_equal "Commit 5\n",   commit[0].message
    assert_equal "Commit 3\n",   commit[2].message
    assert_not_nil               commit[5]
    assert_nil                   commit[6]

    assert_equal ["Commit 3\n","Commit 2\n"], commit[2,2].map {|c|c.message}
    assert_equal [],             commit[4,0]
    assert_equal [],             commit[6,2]
    assert_nil                   commit[7,2]
    assert_nil                   commit[7,0]
    assert_nil                   commit[2,-1]

    assert_equal ["Commit 4\n","Commit 3\n"], commit[1..2].map {|c|c.message}
    assert_equal ["Commit 4\n","Commit 3\n"], commit[1...3].map {|c|c.message}
    assert_equal [],             commit[4..3]
    assert_equal [],             commit[6..8]
    assert_nil                   commit[7..8]

    assert_equal "Commit 2\n",   commit[/Commit 2/].message
    assert_raise(ArgumentError) {commit[/Commit 2/,1]}
    assert_kind_of Git::Tree,    commit[""]
    assert_kind_of Git::Blob,    commit[".gitignore"]
    assert_raise(ArgumentError) {commit[".gitignore",1]}
  end

  def test_should_have_metadata
    assert_equal "Initial revision\n", @head.message
    assert_equal "Him",         @head.author.name
    assert_equal "Him",         @head.committer.name
    assert_equal "him@him.him", @head.author.email
    assert_equal "him@him.him", @head.committer.email
    assert @head.parents.empty?
  end

end
