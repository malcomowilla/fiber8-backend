require "test_helper"

class SmsProviderSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sms_provider_setting = sms_provider_settings(:one)
  end

  test "should get index" do
    get sms_provider_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_sms_provider_setting_url
    assert_response :success
  end

  test "should create sms_provider_setting" do
    assert_difference("SmsProviderSetting.count") do
      post sms_provider_settings_url, params: { sms_provider_setting: { sms_provider: @sms_provider_setting.sms_provider } }
    end

    assert_redirected_to sms_provider_setting_url(SmsProviderSetting.last)
  end

  test "should show sms_provider_setting" do
    get sms_provider_setting_url(@sms_provider_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_sms_provider_setting_url(@sms_provider_setting)
    assert_response :success
  end

  test "should update sms_provider_setting" do
    patch sms_provider_setting_url(@sms_provider_setting), params: { sms_provider_setting: { sms_provider: @sms_provider_setting.sms_provider } }
    assert_redirected_to sms_provider_setting_url(@sms_provider_setting)
  end

  test "should destroy sms_provider_setting" do
    assert_difference("SmsProviderSetting.count", -1) do
      delete sms_provider_setting_url(@sms_provider_setting)
    end

    assert_redirected_to sms_provider_settings_url
  end
end
