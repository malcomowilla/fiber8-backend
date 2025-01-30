require "test_helper"

class SystemAdminEmailSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_admin_email_setting = system_admin_email_settings(:one)
  end

  test "should get index" do
    get system_admin_email_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_system_admin_email_setting_url
    assert_response :success
  end

  test "should create system_admin_email_setting" do
    assert_difference("SystemAdminEmailSetting.count") do
      post system_admin_email_settings_url, params: { system_admin_email_setting: { api_keydomain: @system_admin_email_setting.api_keydomain, sender_email: @system_admin_email_setting.sender_email, smtp_host: @system_admin_email_setting.smtp_host, smtp_password: @system_admin_email_setting.smtp_password, smtp_username: @system_admin_email_setting.smtp_username, system_admin_id: @system_admin_email_setting.system_admin_id } }
    end

    assert_redirected_to system_admin_email_setting_url(SystemAdminEmailSetting.last)
  end

  test "should show system_admin_email_setting" do
    get system_admin_email_setting_url(@system_admin_email_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_admin_email_setting_url(@system_admin_email_setting)
    assert_response :success
  end

  test "should update system_admin_email_setting" do
    patch system_admin_email_setting_url(@system_admin_email_setting), params: { system_admin_email_setting: { api_keydomain: @system_admin_email_setting.api_keydomain, sender_email: @system_admin_email_setting.sender_email, smtp_host: @system_admin_email_setting.smtp_host, smtp_password: @system_admin_email_setting.smtp_password, smtp_username: @system_admin_email_setting.smtp_username, system_admin_id: @system_admin_email_setting.system_admin_id } }
    assert_redirected_to system_admin_email_setting_url(@system_admin_email_setting)
  end

  test "should destroy system_admin_email_setting" do
    assert_difference("SystemAdminEmailSetting.count", -1) do
      delete system_admin_email_setting_url(@system_admin_email_setting)
    end

    assert_redirected_to system_admin_email_settings_url
  end
end
