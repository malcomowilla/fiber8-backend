require "test_helper"

class NasSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nas_setting = nas_settings(:one)
  end

  test "should get index" do
    get nas_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_nas_setting_url
    assert_response :success
  end

  test "should create nas_setting" do
    assert_difference("NasSetting.count") do
      post nas_settings_url, params: { nas_setting: { notification_phone_number: @nas_setting.notification_phone_number, notification_when_unreachable: @nas_setting.notification_when_unreachable, unreachable_duration_minutes: @nas_setting.unreachable_duration_minutes } }
    end

    assert_redirected_to nas_setting_url(NasSetting.last)
  end

  test "should show nas_setting" do
    get nas_setting_url(@nas_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_nas_setting_url(@nas_setting)
    assert_response :success
  end

  test "should update nas_setting" do
    patch nas_setting_url(@nas_setting), params: { nas_setting: { notification_phone_number: @nas_setting.notification_phone_number, notification_when_unreachable: @nas_setting.notification_when_unreachable, unreachable_duration_minutes: @nas_setting.unreachable_duration_minutes } }
    assert_redirected_to nas_setting_url(@nas_setting)
  end

  test "should destroy nas_setting" do
    assert_difference("NasSetting.count", -1) do
      delete nas_setting_url(@nas_setting)
    end

    assert_redirected_to nas_settings_url
  end
end
