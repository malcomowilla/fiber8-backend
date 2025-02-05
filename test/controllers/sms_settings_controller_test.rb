require "test_helper"

class SmsSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sms_setting = sms_settings(:one)
  end

  test "should get index" do
    get sms_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_sms_setting_url
    assert_response :success
  end

  test "should create sms_setting" do
    assert_difference("SmsSetting.count") do
      post sms_settings_url, params: { sms_setting: { accoun_id: @sms_setting.accoun_id, api_key: @sms_setting.api_key, api_secret: @sms_setting.api_secret, sender_id: @sms_setting.sender_id, short_code: @sms_setting.short_code, username: @sms_setting.username } }
    end

    assert_redirected_to sms_setting_url(SmsSetting.last)
  end

  test "should show sms_setting" do
    get sms_setting_url(@sms_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_sms_setting_url(@sms_setting)
    assert_response :success
  end

  test "should update sms_setting" do
    patch sms_setting_url(@sms_setting), params: { sms_setting: { accoun_id: @sms_setting.accoun_id, api_key: @sms_setting.api_key, api_secret: @sms_setting.api_secret, sender_id: @sms_setting.sender_id, short_code: @sms_setting.short_code, username: @sms_setting.username } }
    assert_redirected_to sms_setting_url(@sms_setting)
  end

  test "should destroy sms_setting" do
    assert_difference("SmsSetting.count", -1) do
      delete sms_setting_url(@sms_setting)
    end

    assert_redirected_to sms_settings_url
  end
end
