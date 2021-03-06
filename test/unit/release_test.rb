require File.dirname(__FILE__) + '/../test_helper'

class ReleaseTest < ActiveSupport::TestCase 
  fixtures :releases, :products, :lookup_codes, :users, :release_change_logs
  
  should_have_many :ideas, :dependent => :destroy
  should_belong_to :product
  should_belong_to :release_status
  should_require_unique_attributes :version, :scoped_to => :product_id
  should_ensure_length_in_range :version, (0..20)
  
  def test_invalid_with_empty_attributes
    release = Release.new()
    assert !release.valid?
    assert release.errors.invalid?(:version)
  end

  should "retrieve change_logs" do
    assert !releases(:controller_test).change_logs.empty?
    assert !releases(:controller_test).unprocessed_change_logs.empty?
    assert releases(:controller_test).change_logs.size > releases(:controller_test).unprocessed_change_logs.size
  end
  
  def test_invalid_too_long
    release = Release.new(:version => "012345678901234567890x")
    assert !release.valid?
    assert_equal "is too long (maximum is 20 characters)", 
      release.errors.on(:version)
  end
  
  def test_version_ok
    release = Release.new(:version => "01234567890123456789")
    assert release.valid?
  end
  
  def test_valid_with_attributes
    release = Release.new(:version => "9999", 
      :release_status_id => lookup_codes(:release_status_controller_test).id, 
      :product_id => products(:producta).id)
    assert release.valid?
  end
  
  should "retrieve by status" do
    assert !Release.list_by_status(1, 10, 
      lookup_codes(:release_status_controller_test).id).empty?
  end

  should "send notifications without errors" do
    assert_nothing_thrown {
      Release.send_change_notifications(
        release_change_logs(:controller_test_unprocessed).release.id)
    }
  end
end