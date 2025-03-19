require "test_helper"

class DialUpMpesaSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dial_up_mpesa_setting = dial_up_mpesa_settings(:one)
  end

  test "should get index" do
    get dial_up_mpesa_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_dial_up_mpesa_setting_url
    assert_response :success
  end

  test "should create dial_up_mpesa_setting" do
    assert_difference("DialUpMpesaSetting.count") do
      post dial_up_mpesa_settings_url, params: { dial_up_mpesa_setting: { account_type: @dial_up_mpesa_setting.account_type, consumer_key: @dial_up_mpesa_setting.consumer_key, consumer_secret: @dial_up_mpesa_setting.consumer_secret, passkey: @dial_up_mpesa_setting.passkey, short_code: @dial_up_mpesa_setting.short_code } }
    end

    assert_redirected_to dial_up_mpesa_setting_url(DialUpMpesaSetting.last)
  end

  test "should show dial_up_mpesa_setting" do
    get dial_up_mpesa_setting_url(@dial_up_mpesa_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_dial_up_mpesa_setting_url(@dial_up_mpesa_setting)
    assert_response :success
  end

  test "should update dial_up_mpesa_setting" do
    patch dial_up_mpesa_setting_url(@dial_up_mpesa_setting), params: { dial_up_mpesa_setting: { account_type: @dial_up_mpesa_setting.account_type, consumer_key: @dial_up_mpesa_setting.consumer_key, consumer_secret: @dial_up_mpesa_setting.consumer_secret, passkey: @dial_up_mpesa_setting.passkey, short_code: @dial_up_mpesa_setting.short_code } }
    assert_redirected_to dial_up_mpesa_setting_url(@dial_up_mpesa_setting)
  end

  test "should destroy dial_up_mpesa_setting" do
    assert_difference("DialUpMpesaSetting.count", -1) do
      delete dial_up_mpesa_setting_url(@dial_up_mpesa_setting)
    end

    assert_redirected_to dial_up_mpesa_settings_url
  end
end
