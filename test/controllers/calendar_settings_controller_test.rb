require "test_helper"

class CalendarSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @calendar_setting = calendar_settings(:one)
  end

  test "should get index" do
    get calendar_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_calendar_setting_url
    assert_response :success
  end

  test "should create calendar_setting" do
    assert_difference("CalendarSetting.count") do
      post calendar_settings_url, params: { calendar_setting: { account_id: @calendar_setting.account_id, start_in_hours: @calendar_setting.start_in_hours, start_in_minutes: @calendar_setting.start_in_minutes } }
    end

    assert_redirected_to calendar_setting_url(CalendarSetting.last)
  end

  test "should show calendar_setting" do
    get calendar_setting_url(@calendar_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_calendar_setting_url(@calendar_setting)
    assert_response :success
  end

  test "should update calendar_setting" do
    patch calendar_setting_url(@calendar_setting), params: { calendar_setting: { account_id: @calendar_setting.account_id, start_in_hours: @calendar_setting.start_in_hours, start_in_minutes: @calendar_setting.start_in_minutes } }
    assert_redirected_to calendar_setting_url(@calendar_setting)
  end

  test "should destroy calendar_setting" do
    assert_difference("CalendarSetting.count", -1) do
      delete calendar_setting_url(@calendar_setting)
    end

    assert_redirected_to calendar_settings_url
  end
end
