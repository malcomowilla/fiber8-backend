require "application_system_test_case"

class NasSettingsTest < ApplicationSystemTestCase
  setup do
    @nas_setting = nas_settings(:one)
  end

  test "visiting the index" do
    visit nas_settings_url
    assert_selector "h1", text: "Nas settings"
  end

  test "should create nas setting" do
    visit nas_settings_url
    click_on "New nas setting"

    fill_in "Notification phone number", with: @nas_setting.notification_phone_number
    check "Notification when unreachable" if @nas_setting.notification_when_unreachable
    fill_in "Unreachable duration minutes", with: @nas_setting.unreachable_duration_minutes
    click_on "Create Nas setting"

    assert_text "Nas setting was successfully created"
    click_on "Back"
  end

  test "should update Nas setting" do
    visit nas_setting_url(@nas_setting)
    click_on "Edit this nas setting", match: :first

    fill_in "Notification phone number", with: @nas_setting.notification_phone_number
    check "Notification when unreachable" if @nas_setting.notification_when_unreachable
    fill_in "Unreachable duration minutes", with: @nas_setting.unreachable_duration_minutes
    click_on "Update Nas setting"

    assert_text "Nas setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Nas setting" do
    visit nas_setting_url(@nas_setting)
    click_on "Destroy this nas setting", match: :first

    assert_text "Nas setting was successfully destroyed"
  end
end
