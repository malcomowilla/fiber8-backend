require "application_system_test_case"

class SystemAdminEmailSettingsTest < ApplicationSystemTestCase
  setup do
    @system_admin_email_setting = system_admin_email_settings(:one)
  end

  test "visiting the index" do
    visit system_admin_email_settings_url
    assert_selector "h1", text: "System admin email settings"
  end

  test "should create system admin email setting" do
    visit system_admin_email_settings_url
    click_on "New system admin email setting"

    fill_in "Api keydomain", with: @system_admin_email_setting.api_keydomain
    fill_in "Sender email", with: @system_admin_email_setting.sender_email
    fill_in "Smtp host", with: @system_admin_email_setting.smtp_host
    fill_in "Smtp password", with: @system_admin_email_setting.smtp_password
    fill_in "Smtp username", with: @system_admin_email_setting.smtp_username
    fill_in "System admin", with: @system_admin_email_setting.system_admin_id
    click_on "Create System admin email setting"

    assert_text "System admin email setting was successfully created"
    click_on "Back"
  end

  test "should update System admin email setting" do
    visit system_admin_email_setting_url(@system_admin_email_setting)
    click_on "Edit this system admin email setting", match: :first

    fill_in "Api keydomain", with: @system_admin_email_setting.api_keydomain
    fill_in "Sender email", with: @system_admin_email_setting.sender_email
    fill_in "Smtp host", with: @system_admin_email_setting.smtp_host
    fill_in "Smtp password", with: @system_admin_email_setting.smtp_password
    fill_in "Smtp username", with: @system_admin_email_setting.smtp_username
    fill_in "System admin", with: @system_admin_email_setting.system_admin_id
    click_on "Update System admin email setting"

    assert_text "System admin email setting was successfully updated"
    click_on "Back"
  end

  test "should destroy System admin email setting" do
    visit system_admin_email_setting_url(@system_admin_email_setting)
    click_on "Destroy this system admin email setting", match: :first

    assert_text "System admin email setting was successfully destroyed"
  end
end
