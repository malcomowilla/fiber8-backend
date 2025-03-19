require "application_system_test_case"

class DialUpMpesaSettingsTest < ApplicationSystemTestCase
  setup do
    @dial_up_mpesa_setting = dial_up_mpesa_settings(:one)
  end

  test "visiting the index" do
    visit dial_up_mpesa_settings_url
    assert_selector "h1", text: "Dial up mpesa settings"
  end

  test "should create dial up mpesa setting" do
    visit dial_up_mpesa_settings_url
    click_on "New dial up mpesa setting"

    fill_in "Account type", with: @dial_up_mpesa_setting.account_type
    fill_in "Consumer key", with: @dial_up_mpesa_setting.consumer_key
    fill_in "Consumer secret", with: @dial_up_mpesa_setting.consumer_secret
    fill_in "Passkey", with: @dial_up_mpesa_setting.passkey
    fill_in "Short code", with: @dial_up_mpesa_setting.short_code
    click_on "Create Dial up mpesa setting"

    assert_text "Dial up mpesa setting was successfully created"
    click_on "Back"
  end

  test "should update Dial up mpesa setting" do
    visit dial_up_mpesa_setting_url(@dial_up_mpesa_setting)
    click_on "Edit this dial up mpesa setting", match: :first

    fill_in "Account type", with: @dial_up_mpesa_setting.account_type
    fill_in "Consumer key", with: @dial_up_mpesa_setting.consumer_key
    fill_in "Consumer secret", with: @dial_up_mpesa_setting.consumer_secret
    fill_in "Passkey", with: @dial_up_mpesa_setting.passkey
    fill_in "Short code", with: @dial_up_mpesa_setting.short_code
    click_on "Update Dial up mpesa setting"

    assert_text "Dial up mpesa setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Dial up mpesa setting" do
    visit dial_up_mpesa_setting_url(@dial_up_mpesa_setting)
    click_on "Destroy this dial up mpesa setting", match: :first

    assert_text "Dial up mpesa setting was successfully destroyed"
  end
end
