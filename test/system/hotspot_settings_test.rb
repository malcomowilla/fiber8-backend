require "application_system_test_case"

class HotspotSettingsTest < ApplicationSystemTestCase
  setup do
    @hotspot_setting = hotspot_settings(:one)
  end

  test "visiting the index" do
    visit hotspot_settings_url
    assert_selector "h1", text: "Hotspot settings"
  end

  test "should create hotspot setting" do
    visit hotspot_settings_url
    click_on "New hotspot setting"

    fill_in "Account", with: @hotspot_setting.account_id
    fill_in "Hotspot banner", with: @hotspot_setting.hotspot_banner
    fill_in "Hotspot info", with: @hotspot_setting.hotspot_info
    fill_in "Hotspot name", with: @hotspot_setting.hotspot_name
    fill_in "Phone number", with: @hotspot_setting.phone_number
    click_on "Create Hotspot setting"

    assert_text "Hotspot setting was successfully created"
    click_on "Back"
  end

  test "should update Hotspot setting" do
    visit hotspot_setting_url(@hotspot_setting)
    click_on "Edit this hotspot setting", match: :first

    fill_in "Account", with: @hotspot_setting.account_id
    fill_in "Hotspot banner", with: @hotspot_setting.hotspot_banner
    fill_in "Hotspot info", with: @hotspot_setting.hotspot_info
    fill_in "Hotspot name", with: @hotspot_setting.hotspot_name
    fill_in "Phone number", with: @hotspot_setting.phone_number
    click_on "Update Hotspot setting"

    assert_text "Hotspot setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot setting" do
    visit hotspot_setting_url(@hotspot_setting)
    click_on "Destroy this hotspot setting", match: :first

    assert_text "Hotspot setting was successfully destroyed"
  end
end
