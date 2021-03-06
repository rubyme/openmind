require File.dirname(__FILE__) + '/../test_helper'

class ForumTest < ActiveSupport::TestCase 
  fixtures :users, :roles, :topics, :forums, :lookup_codes,
    :user_topic_reads, :groups

  should_have_many :topics, :dependent => :delete_all
  should_have_many :comments, :comments_by_topic
  should_belong_to :link_set, :forum_group, :power_user_group
  should_have_and_belong_to_many :mediators, :watchers, :groups, 
    :enterprise_types
  should_require_attributes :description
  should_require_unique_attributes :name
  should_ensure_length_in_range :name, (0..50)
  should_ensure_length_in_range :description, (0..150)

  context "test can delete" do
    should "allow delete" do
      assert forums(:empty_bugs_forum).can_delete?
    end
    
    should "allow not delete" do
      assert !forums(:bugs_forum).can_delete?
    end
  end
  
  context "test can edit" do
    should "allow edit" do
      assert forums(:bugs_forum).can_edit?(users(:allroles))
    end
    
    should "allow not edit" do
      assert !forums(:bugs_forum).can_edit?(users(:quentin))
    end
  end

  context "testing power_user?" do
    should "indicate no for no power_user on forum" do
      assert !forums(:bugs_forum_restrict_creation).power_user?(users(:quentin))
    end
  end
  
  context "testing unread comment logic" do
    should "return unread comment" do
      assert !topics(:bug_topic1).forum.unread_topics(users(:quentin)).empty?
    end
    
    should "not return unread comment" do
      # forum with no topics
      assert forums(:empty_bugs_forum).unread_topics(users(:quentin)).empty?

      # forum that has been read
      assert topics(:bug_topic1).forum.unread_topics(users(:aaron)).empty?
    end
  end
  
  context "testing watchers" do
    should "add and remove watches" do
      assert forums(:bugs_forum).topics.size > 0
      forums(:bugs_forum).remove_all_topic_watches(users(:aaron))
      forum = Forum.find(forums(:bugs_forum).id)
      count = all_watchers(forum)
      
      forums(:bugs_forum).watch_all_topics(users(:aaron))
      forum = Forum.find(forums(:bugs_forum).id)
      assert_equal forums(:bugs_forum).topics.size + count, all_watchers(forum)
    end
  end
  
  context "testing can_see?" do
    should "be able to see" do
      # mediator
      assert forums(:forum_restricted_to_user_group).can_edit?(users(:quentin))
      assert forums(:forum_restricted_to_user_group).can_see?(users(:quentin))
      # prodmgr
      assert users(:prodmgr).prodmgr?
      assert forums(:forum_restricted_to_user_group).can_see?(users(:prodmgr))
      assert forums(:forum_restricted_to_user_group).can_edit?(users(:prodmgr))
      # group member
      assert forums(:forum_restricted_to_user_group).can_see?(users(:bob))
      assert !forums(:forum_restricted_to_user_group).can_edit?(users(:bob))
      # public
      assert forums(:bugs_forum).can_see?(users(:aaron))
      
      # mediator
      assert forums(:forum_restricted_to_enterprise_type).can_edit?(users(:quentin))
      assert forums(:forum_restricted_to_enterprise_type).can_see?(users(:quentin))
      # prodmgr
      assert users(:prodmgr).prodmgr?
      assert forums(:forum_restricted_to_enterprise_type).can_see?(users(:prodmgr))
      assert forums(:forum_restricted_to_enterprise_type).can_edit?(users(:prodmgr))
      # group member
      assert forums(:forum_restricted_to_enterprise_type).can_see?(users(:judy))
      assert !forums(:forum_restricted_to_enterprise_type).can_edit?(users(:judy))
      # public
      assert forums(:bugs_forum).can_see?(users(:aaron))
    end
    
    should "not be able to see" do
      assert !forums(:forum_restricted_to_user_group).groups.empty?
      assert !forums(:forum_restricted_to_user_group).can_edit?(users(:aaron))
      assert !users(:aaron).prodmgr?
      assert !forums(:forum_restricted_to_user_group).can_see?(users(:aaron))
      assert !forums(:forum_restricted_to_enterprise_type).can_see?(users(:bob))
      assert !forums(:forum_restricted_to_user_group).can_see?(users(:judy))
    end
  end
  
  # Replace this with your real tests.
  def test_invalid_with_empty_attributes
    forum = Forum.new(:name => "", :description => "")
    assert !forum.valid?
    
    assert forum.errors.invalid?(:name)
    assert_equal "can't be blank", 
      forum.errors.on(:name)
    
    assert forum.errors.invalid?(:description)
    assert_equal "can't be blank", 
      forum.errors.on(:description)
  end
  
  def test_name_invalid_too_long
    forum = Forum.new(:name => "0123456789012345678901234567890123456789012345678901")
    assert !forum.valid?
    assert_equal "is too long (maximum is 50 characters)", 
      forum.errors.on(:name)
  end
  
  def test_description_invalid_too_long
    forum = Forum.new(:description => "0123456789012345678901234567890123456789012345678900123456789012345678901234567890123456789012345678900123456789012345678901234567890123456789012345678901")
    assert !forum.valid?
    assert_equal "is too long (maximum is 150 characters)", 
      forum.errors.on(:description)
  end
  
  def test_valid_with_attributes
    forum = Forum.new(:name => "bugs2", :description => "wassup")
    assert forum.valid?
  end
  
  def test_list
    assert Forum.list(1, 10).size > 0
  end
  
  def test_mediators
    forum = Forum.find forums(:bugs_forum).id
    assert_equal 3, forum.topics.size
    assert !forum.can_delete?
    assert_equal 1, forum.mediators.count
  end
  
  def test_list_by_forum_group
    assert !Forum.list_by_forum_group.empty?
    assert !Forum.list_by_forum_group(lookup_codes(:forum_group_abc)).empty?
  end
  
  def test_can_create_topic
    assert !forums(:bugs_forum).can_create_topic?(:false)
    assert forums(:bugs_forum).can_create_topic?(users(:quentin))
    assert !forums(:bugs_forum_restrict_creation).can_create_topic?(users(:quentin))
    assert forums(:bugs_forum_restrict_creation).can_create_topic?(users(:allroles))
  end
  
  private
  
  def all_watchers forum
    count = 0
    for topic in forum.topics
      count += topic.watchers.size
    end
    count
  end
end