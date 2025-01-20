require "application_system_test_case"

class RouterSettingsTest < ApplicationSystemTestCase
  setup do
    @router_setting = router_settings(:one)
  end

  test "visiting the index" do
    visit router_settings_url
    assert_selector "h1", text: "Router settings"
  end

  test "should create router setting" do
    visit router_settings_url
    click_on "New router setting"

    fill_in "Router name", with: @router_setting.router_name
    click_on "Create Router setting"

    assert_text "Router setting was successfully created"
    click_on "Back"
  end

  test "should update Router setting" do
    visit router_setting_url(@router_setting)
    click_on "Edit this router setting", match: :first

    fill_in "Router name", with: @router_setting.router_name
    click_on "Update Router setting"

    assert_text "Router setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Router setting" do
    visit router_setting_url(@router_setting)
    click_on "Destroy this router setting", match: :first

    assert_text "Router setting was successfully destroyed"
  end
end
