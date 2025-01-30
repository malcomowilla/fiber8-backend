require "test_helper"

class EmailSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @email_setting = email_settings(:one)
  end

  test "should get index" do
    get email_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_email_setting_url
    assert_response :success
  end

  test "should create email_setting" do
    assert_difference("EmailSetting.count") do
      post email_settings_url, params: { email_setting: { api_key: @email_setting.api_key, domain: @email_setting.domain, sender_email: @email_setting.sender_email, smtp_host: @email_setting.smtp_host, smtp_password: @email_setting.smtp_password, smtp_username: @email_setting.smtp_username } }
    end

    assert_redirected_to email_setting_url(EmailSetting.last)
  end

  test "should show email_setting" do
    get email_setting_url(@email_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_email_setting_url(@email_setting)
    assert_response :success
  end

  test "should update email_setting" do
    patch email_setting_url(@email_setting), params: { email_setting: { api_key: @email_setting.api_key, domain: @email_setting.domain, sender_email: @email_setting.sender_email, smtp_host: @email_setting.smtp_host, smtp_password: @email_setting.smtp_password, smtp_username: @email_setting.smtp_username } }
    assert_redirected_to email_setting_url(@email_setting)
  end

  test "should destroy email_setting" do
    assert_difference("EmailSetting.count", -1) do
      delete email_setting_url(@email_setting)
    end

    assert_redirected_to email_settings_url
  end
end
