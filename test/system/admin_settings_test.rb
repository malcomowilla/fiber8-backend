require "application_system_test_case"

class AdminSettingsTest < ApplicationSystemTestCase
  setup do
    @admin_setting = admin_settings(:one)
  end

  test "visiting the index" do
    visit admin_settings_url
    assert_selector "h1", text: "Admin settings"
  end

  test "should create admin setting" do
    visit admin_settings_url
    click_on "New admin setting"

    fill_in "Account", with: @admin_setting.account_id
    check "Check inactive days" if @admin_setting.check_inactive_days
    check "Check inactive hrs" if @admin_setting.check_inactive_hrs
    check "Check inactive minutes" if @admin_setting.check_inactive_minutes
    check "Enable 2fa for admin email" if @admin_setting.enable_2fa_for_admin_email
    check "Enable 2fa for admin passkeys" if @admin_setting.enable_2fa_for_admin_passkeys
    check "Enable 2fa for admin sms" if @admin_setting.enable_2fa_for_admin_sms
    check "Send password via email" if @admin_setting.send_password_via_email
    check "Send password via sms" if @admin_setting.send_password_via_sms
    fill_in "User", with: @admin_setting.user_id
    click_on "Create Admin setting"

    assert_text "Admin setting was successfully created"
    click_on "Back"
  end

  test "should update Admin setting" do
    visit admin_setting_url(@admin_setting)
    click_on "Edit this admin setting", match: :first

    fill_in "Account", with: @admin_setting.account_id
    check "Check inactive days" if @admin_setting.check_inactive_days
    check "Check inactive hrs" if @admin_setting.check_inactive_hrs
    check "Check inactive minutes" if @admin_setting.check_inactive_minutes
    check "Enable 2fa for admin email" if @admin_setting.enable_2fa_for_admin_email
    check "Enable 2fa for admin passkeys" if @admin_setting.enable_2fa_for_admin_passkeys
    check "Enable 2fa for admin sms" if @admin_setting.enable_2fa_for_admin_sms
    check "Send password via email" if @admin_setting.send_password_via_email
    check "Send password via sms" if @admin_setting.send_password_via_sms
    fill_in "User", with: @admin_setting.user_id
    click_on "Update Admin setting"

    assert_text "Admin setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Admin setting" do
    visit admin_setting_url(@admin_setting)
    click_on "Destroy this admin setting", match: :first

    assert_text "Admin setting was successfully destroyed"
  end
end
