require "test_helper"

class HotspotMpesaSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_mpesa_setting = hotspot_mpesa_settings(:one)
  end

  test "should get index" do
    get hotspot_mpesa_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_mpesa_setting_url
    assert_response :success
  end

  test "should create hotspot_mpesa_setting" do
    assert_difference("HotspotMpesaSetting.count") do
      post hotspot_mpesa_settings_url, params: { hotspot_mpesa_setting: { account_type: @hotspot_mpesa_setting.account_type, consumer_key: @hotspot_mpesa_setting.consumer_key, consumer_secret: @hotspot_mpesa_setting.consumer_secret, passkey: @hotspot_mpesa_setting.passkey, short_code: @hotspot_mpesa_setting.short_code } }
    end

    assert_redirected_to hotspot_mpesa_setting_url(HotspotMpesaSetting.last)
  end

  test "should show hotspot_mpesa_setting" do
    get hotspot_mpesa_setting_url(@hotspot_mpesa_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_mpesa_setting_url(@hotspot_mpesa_setting)
    assert_response :success
  end

  test "should update hotspot_mpesa_setting" do
    patch hotspot_mpesa_setting_url(@hotspot_mpesa_setting), params: { hotspot_mpesa_setting: { account_type: @hotspot_mpesa_setting.account_type, consumer_key: @hotspot_mpesa_setting.consumer_key, consumer_secret: @hotspot_mpesa_setting.consumer_secret, passkey: @hotspot_mpesa_setting.passkey, short_code: @hotspot_mpesa_setting.short_code } }
    assert_redirected_to hotspot_mpesa_setting_url(@hotspot_mpesa_setting)
  end

  test "should destroy hotspot_mpesa_setting" do
    assert_difference("HotspotMpesaSetting.count", -1) do
      delete hotspot_mpesa_setting_url(@hotspot_mpesa_setting)
    end

    assert_redirected_to hotspot_mpesa_settings_url
  end
end
