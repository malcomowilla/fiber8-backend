require "application_system_test_case"

class LicenseSettingsTest < ApplicationSystemTestCase
  setup do
    @license_setting = license_settings(:one)
  end

  test "visiting the index" do
    visit license_settings_url
    assert_selector "h1", text: "License settings"
  end

  test "should create license setting" do
    visit license_settings_url
    click_on "New license setting"

    fill_in "Expiry warning days", with: @license_setting.expiry_warning_days
    click_on "Create License setting"

    assert_text "License setting was successfully created"
    click_on "Back"
  end

  test "should update License setting" do
    visit license_setting_url(@license_setting)
    click_on "Edit this license setting", match: :first

    fill_in "Expiry warning days", with: @license_setting.expiry_warning_days
    click_on "Update License setting"

    assert_text "License setting was successfully updated"
    click_on "Back"
  end

  test "should destroy License setting" do
    visit license_setting_url(@license_setting)
    click_on "Destroy this license setting", match: :first

    assert_text "License setting was successfully destroyed"
  end
end
