require File.join(File.dirname(File.expand_path(__FILE__)),'test_helper')

class IdentityTest < Test::Unit::TestCase

  def test_should_handle_weird_zone_offsets
    identity = Girth::Identity.new("Me","me@me.me",Time.utc(2000))
    identity.zone = "-0315"
    assert_equal -(3*3600+15*60), identity.utc_offset
    assert_equal "#<Girth::Identity Me <me@me.me> Fri Dec 31 20:45:00 1999 -0315>", identity.inspect
  end

  def test_should_strictly_parse
    assert_raise(Girth::Error) { Girth::Identity.parse("Me <me@me.me> x +0000") }
    identity = Girth::Identity.parse("Me <me@me.me> 0 +0000")
    assert_equal "Me", identity.name
    assert_equal "me@me.me", identity.email
    assert_equal Time.at(0), identity.time
    assert_equal 0, identity.utc_offset
  end

  def test_should_set_and_restore_as
    committer_name = ENV["GIT_COMMITTER_NAME"]
    author_date    = ENV["GIT_AUTHOR_DATE"]
    ENV["GIT_COMMITTER_NAME"] = "You"
    ENV["GIT_AUTHOR_DATE"]    = nil

    identity = Girth::Identity.new("Me", "me@me.me", Time.utc(2000))
    identity.as(:author, :committer) do
      assert_equal "Me",        ENV["GIT_COMMITTER_NAME"]
      assert_equal identity.date, ENV["GIT_AUTHOR_DATE"]
    end

    assert_equal "You", ENV["GIT_COMMITTER_NAME"]
    assert_nil          ENV["GIT_AUTHOR_DATE"]
  ensure
    ENV["GIT_COMMITTER_NAME"] = committer_name
    ENV["GIT_AUTHOR_DATE"]    = author_date
  end

  def test_should_function_without_time
    identity = Girth::Identity.new("Me", "me@me.me")
    assert_nil identity.utc_offset
    assert_nil identity.time
    assert_nil identity.date
    assert_match /^Me <me@me\.me> \d\d+ [+-]\d{4}$/, identity.to_s
    assert_equal "#<Girth::Identity Me <me@me.me> >", identity.inspect
  end

end
