require "application_system_test_case"

class AdSettingsTest < ApplicationSystemTestCase
  setup do
    @ad_setting = ad_settings(:one)
  end

  test "visiting the index" do
    visit ad_settings_url
    assert_selector "h1", text: "Ad settings"
  end

  test "should create ad setting" do
    visit ad_settings_url
    click_on "New ad setting"

    fill_in "Account", with: @ad_setting.account_id
    check "Enabled" if @ad_setting.enabled
    check "To left" if @ad_setting.to_left
    check "To right" if @ad_setting.to_right
    check "To top" if @ad_setting.to_top
    click_on "Create Ad setting"

    assert_text "Ad setting was successfully created"
    click_on "Back"
  end

  test "should update Ad setting" do
    visit ad_setting_url(@ad_setting)
    click_on "Edit this ad setting", match: :first

    fill_in "Account", with: @ad_setting.account_id
    check "Enabled" if @ad_setting.enabled
    check "To left" if @ad_setting.to_left
    check "To right" if @ad_setting.to_right
    check "To top" if @ad_setting.to_top
    click_on "Update Ad setting"

    assert_text "Ad setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Ad setting" do
    visit ad_setting_url(@ad_setting)
    click_on "Destroy this ad setting", match: :first

    assert_text "Ad setting was successfully destroyed"
  end
end
