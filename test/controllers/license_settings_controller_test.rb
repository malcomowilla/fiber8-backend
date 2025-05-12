require "test_helper"

class LicenseSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @license_setting = license_settings(:one)
  end

  test "should get index" do
    get license_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_license_setting_url
    assert_response :success
  end

  test "should create license_setting" do
    assert_difference("LicenseSetting.count") do
      post license_settings_url, params: { license_setting: { expiry_warning_days: @license_setting.expiry_warning_days } }
    end

    assert_redirected_to license_setting_url(LicenseSetting.last)
  end

  test "should show license_setting" do
    get license_setting_url(@license_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_license_setting_url(@license_setting)
    assert_response :success
  end

  test "should update license_setting" do
    patch license_setting_url(@license_setting), params: { license_setting: { expiry_warning_days: @license_setting.expiry_warning_days } }
    assert_redirected_to license_setting_url(@license_setting)
  end

  test "should destroy license_setting" do
    assert_difference("LicenseSetting.count", -1) do
      delete license_setting_url(@license_setting)
    end

    assert_redirected_to license_settings_url
  end
end
