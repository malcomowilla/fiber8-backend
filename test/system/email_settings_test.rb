require "application_system_test_case"

class EmailSettingsTest < ApplicationSystemTestCase
  setup do
    @email_setting = email_settings(:one)
  end

  test "visiting the index" do
    visit email_settings_url
    assert_selector "h1", text: "Email settings"
  end

  test "should create email setting" do
    visit email_settings_url
    click_on "New email setting"

    fill_in "Api key", with: @email_setting.api_key
    fill_in "Domain", with: @email_setting.domain
    fill_in "Sender email", with: @email_setting.sender_email
    fill_in "Smtp host", with: @email_setting.smtp_host
    fill_in "Smtp password", with: @email_setting.smtp_password
    fill_in "Smtp username", with: @email_setting.smtp_username
    click_on "Create Email setting"

    assert_text "Email setting was successfully created"
    click_on "Back"
  end

  test "should update Email setting" do
    visit email_setting_url(@email_setting)
    click_on "Edit this email setting", match: :first

    fill_in "Api key", with: @email_setting.api_key
    fill_in "Domain", with: @email_setting.domain
    fill_in "Sender email", with: @email_setting.sender_email
    fill_in "Smtp host", with: @email_setting.smtp_host
    fill_in "Smtp password", with: @email_setting.smtp_password
    fill_in "Smtp username", with: @email_setting.smtp_username
    click_on "Update Email setting"

    assert_text "Email setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Email setting" do
    visit email_setting_url(@email_setting)
    click_on "Destroy this email setting", match: :first

    assert_text "Email setting was successfully destroyed"
  end
end
