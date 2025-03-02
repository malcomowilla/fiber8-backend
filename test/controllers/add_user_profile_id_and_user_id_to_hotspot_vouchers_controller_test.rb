require "test_helper"

class AddUserProfileIdAndUserIdToHotspotVouchersControllerTest < ActionDispatch::IntegrationTest
  test "should get user_manager_user_id" do
    get add_user_profile_id_and_user_id_to_hotspot_vouchers_user_manager_user_id_url
    assert_response :success
  end

  test "should get user_profile_id" do
    get add_user_profile_id_and_user_id_to_hotspot_vouchers_user_profile_id_url
    assert_response :success
  end
end
