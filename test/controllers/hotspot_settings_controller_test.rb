require "test_helper"

class HotspotSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_setting = hotspot_settings(:one)
  end

  test "should get index" do
    get hotspot_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_setting_url
    assert_response :success
  end

  test "should create hotspot_setting" do
    assert_difference("HotspotSetting.count") do
      post hotspot_settings_url, params: { hotspot_setting: { account_id: @hotspot_setting.account_id, hotspot_banner: @hotspot_setting.hotspot_banner, hotspot_info: @hotspot_setting.hotspot_info, hotspot_name: @hotspot_setting.hotspot_name, phone_number: @hotspot_setting.phone_number } }
    end

    assert_redirected_to hotspot_setting_url(HotspotSetting.last)
  end

  test "should show hotspot_setting" do
    get hotspot_setting_url(@hotspot_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_setting_url(@hotspot_setting)
    assert_response :success
  end

  test "should update hotspot_setting" do
    patch hotspot_setting_url(@hotspot_setting), params: { hotspot_setting: { account_id: @hotspot_setting.account_id, hotspot_banner: @hotspot_setting.hotspot_banner, hotspot_info: @hotspot_setting.hotspot_info, hotspot_name: @hotspot_setting.hotspot_name, phone_number: @hotspot_setting.phone_number } }
    assert_redirected_to hotspot_setting_url(@hotspot_setting)
  end

  test "should destroy hotspot_setting" do
    assert_difference("HotspotSetting.count", -1) do
      delete hotspot_setting_url(@hotspot_setting)
    end

    assert_redirected_to hotspot_settings_url
  end
end
