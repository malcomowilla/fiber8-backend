require "application_system_test_case"

class SmsProviderSettingsTest < ApplicationSystemTestCase
  setup do
    @sms_provider_setting = sms_provider_settings(:one)
  end

  test "visiting the index" do
    visit sms_provider_settings_url
    assert_selector "h1", text: "Sms provider settings"
  end

  test "should create sms provider setting" do
    visit sms_provider_settings_url
    click_on "New sms provider setting"

    fill_in "Sms provider", with: @sms_provider_setting.sms_provider
    click_on "Create Sms provider setting"

    assert_text "Sms provider setting was successfully created"
    click_on "Back"
  end

  test "should update Sms provider setting" do
    visit sms_provider_setting_url(@sms_provider_setting)
    click_on "Edit this sms provider setting", match: :first

    fill_in "Sms provider", with: @sms_provider_setting.sms_provider
    click_on "Update Sms provider setting"

    assert_text "Sms provider setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Sms provider setting" do
    visit sms_provider_setting_url(@sms_provider_setting)
    click_on "Destroy this sms provider setting", match: :first

    assert_text "Sms provider setting was successfully destroyed"
  end
end
