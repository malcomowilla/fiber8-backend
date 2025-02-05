require "application_system_test_case"

class SmsSettingsTest < ApplicationSystemTestCase
  setup do
    @sms_setting = sms_settings(:one)
  end

  test "visiting the index" do
    visit sms_settings_url
    assert_selector "h1", text: "Sms settings"
  end

  test "should create sms setting" do
    visit sms_settings_url
    click_on "New sms setting"

    fill_in "Accoun", with: @sms_setting.accoun_id
    fill_in "Api key", with: @sms_setting.api_key
    fill_in "Api secret", with: @sms_setting.api_secret
    fill_in "Sender", with: @sms_setting.sender_id
    fill_in "Short code", with: @sms_setting.short_code
    fill_in "Username", with: @sms_setting.username
    click_on "Create Sms setting"

    assert_text "Sms setting was successfully created"
    click_on "Back"
  end

  test "should update Sms setting" do
    visit sms_setting_url(@sms_setting)
    click_on "Edit this sms setting", match: :first

    fill_in "Accoun", with: @sms_setting.accoun_id
    fill_in "Api key", with: @sms_setting.api_key
    fill_in "Api secret", with: @sms_setting.api_secret
    fill_in "Sender", with: @sms_setting.sender_id
    fill_in "Short code", with: @sms_setting.short_code
    fill_in "Username", with: @sms_setting.username
    click_on "Update Sms setting"

    assert_text "Sms setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Sms setting" do
    visit sms_setting_url(@sms_setting)
    click_on "Destroy this sms setting", match: :first

    assert_text "Sms setting was successfully destroyed"
  end
end
