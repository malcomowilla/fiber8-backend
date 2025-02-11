require "test_helper"

class AdminSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_setting = admin_settings(:one)
  end

  test "should get index" do
    get admin_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_admin_setting_url
    assert_response :success
  end

  test "should create admin_setting" do
    assert_difference("AdminSetting.count") do
      post admin_settings_url, params: { admin_setting: { account_id: @admin_setting.account_id, check_inactive_days: @admin_setting.check_inactive_days, check_inactive_hrs: @admin_setting.check_inactive_hrs, check_inactive_minutes: @admin_setting.check_inactive_minutes, enable_2fa_for_admin_email: @admin_setting.enable_2fa_for_admin_email, enable_2fa_for_admin_passkeys: @admin_setting.enable_2fa_for_admin_passkeys, enable_2fa_for_admin_sms: @admin_setting.enable_2fa_for_admin_sms, send_password_via_email: @admin_setting.send_password_via_email, send_password_via_sms: @admin_setting.send_password_via_sms, user_id: @admin_setting.user_id } }
    end

    assert_redirected_to admin_setting_url(AdminSetting.last)
  end

  test "should show admin_setting" do
    get admin_setting_url(@admin_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_setting_url(@admin_setting)
    assert_response :success
  end

  test "should update admin_setting" do
    patch admin_setting_url(@admin_setting), params: { admin_setting: { account_id: @admin_setting.account_id, check_inactive_days: @admin_setting.check_inactive_days, check_inactive_hrs: @admin_setting.check_inactive_hrs, check_inactive_minutes: @admin_setting.check_inactive_minutes, enable_2fa_for_admin_email: @admin_setting.enable_2fa_for_admin_email, enable_2fa_for_admin_passkeys: @admin_setting.enable_2fa_for_admin_passkeys, enable_2fa_for_admin_sms: @admin_setting.enable_2fa_for_admin_sms, send_password_via_email: @admin_setting.send_password_via_email, send_password_via_sms: @admin_setting.send_password_via_sms, user_id: @admin_setting.user_id } }
    assert_redirected_to admin_setting_url(@admin_setting)
  end

  test "should destroy admin_setting" do
    assert_difference("AdminSetting.count", -1) do
      delete admin_setting_url(@admin_setting)
    end

    assert_redirected_to admin_settings_url
  end
end
