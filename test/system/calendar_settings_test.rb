require "application_system_test_case"

class CalendarSettingsTest < ApplicationSystemTestCase
  setup do
    @calendar_setting = calendar_settings(:one)
  end

  test "visiting the index" do
    visit calendar_settings_url
    assert_selector "h1", text: "Calendar settings"
  end

  test "should create calendar setting" do
    visit calendar_settings_url
    click_on "New calendar setting"

    fill_in "Account", with: @calendar_setting.account_id
    fill_in "Start in hours", with: @calendar_setting.start_in_hours
    fill_in "Start in minutes", with: @calendar_setting.start_in_minutes
    click_on "Create Calendar setting"

    assert_text "Calendar setting was successfully created"
    click_on "Back"
  end

  test "should update Calendar setting" do
    visit calendar_setting_url(@calendar_setting)
    click_on "Edit this calendar setting", match: :first

    fill_in "Account", with: @calendar_setting.account_id
    fill_in "Start in hours", with: @calendar_setting.start_in_hours
    fill_in "Start in minutes", with: @calendar_setting.start_in_minutes
    click_on "Update Calendar setting"

    assert_text "Calendar setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Calendar setting" do
    visit calendar_setting_url(@calendar_setting)
    click_on "Destroy this calendar setting", match: :first

    assert_text "Calendar setting was successfully destroyed"
  end
end
