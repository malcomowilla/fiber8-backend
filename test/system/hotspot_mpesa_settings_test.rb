require "application_system_test_case"

class HotspotMpesaSettingsTest < ApplicationSystemTestCase
  setup do
    @hotspot_mpesa_setting = hotspot_mpesa_settings(:one)
  end

  test "visiting the index" do
    visit hotspot_mpesa_settings_url
    assert_selector "h1", text: "Hotspot mpesa settings"
  end

  test "should create hotspot mpesa setting" do
    visit hotspot_mpesa_settings_url
    click_on "New hotspot mpesa setting"

    fill_in "Account type", with: @hotspot_mpesa_setting.account_type
    fill_in "Consumer key", with: @hotspot_mpesa_setting.consumer_key
    fill_in "Consumer secret", with: @hotspot_mpesa_setting.consumer_secret
    fill_in "Passkey", with: @hotspot_mpesa_setting.passkey
    fill_in "Short code", with: @hotspot_mpesa_setting.short_code
    click_on "Create Hotspot mpesa setting"

    assert_text "Hotspot mpesa setting was successfully created"
    click_on "Back"
  end

  test "should update Hotspot mpesa setting" do
    visit hotspot_mpesa_setting_url(@hotspot_mpesa_setting)
    click_on "Edit this hotspot mpesa setting", match: :first

    fill_in "Account type", with: @hotspot_mpesa_setting.account_type
    fill_in "Consumer key", with: @hotspot_mpesa_setting.consumer_key
    fill_in "Consumer secret", with: @hotspot_mpesa_setting.consumer_secret
    fill_in "Passkey", with: @hotspot_mpesa_setting.passkey
    fill_in "Short code", with: @hotspot_mpesa_setting.short_code
    click_on "Update Hotspot mpesa setting"

    assert_text "Hotspot mpesa setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot mpesa setting" do
    visit hotspot_mpesa_setting_url(@hotspot_mpesa_setting)
    click_on "Destroy this hotspot mpesa setting", match: :first

    assert_text "Hotspot mpesa setting was successfully destroyed"
  end
end
