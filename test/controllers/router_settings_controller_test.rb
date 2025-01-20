require "test_helper"

class RouterSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @router_setting = router_settings(:one)
  end

  test "should get index" do
    get router_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_router_setting_url
    assert_response :success
  end

  test "should create router_setting" do
    assert_difference("RouterSetting.count") do
      post router_settings_url, params: { router_setting: { router_name: @router_setting.router_name } }
    end

    assert_redirected_to router_setting_url(RouterSetting.last)
  end

  test "should show router_setting" do
    get router_setting_url(@router_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_router_setting_url(@router_setting)
    assert_response :success
  end

  test "should update router_setting" do
    patch router_setting_url(@router_setting), params: { router_setting: { router_name: @router_setting.router_name } }
    assert_redirected_to router_setting_url(@router_setting)
  end

  test "should destroy router_setting" do
    assert_difference("RouterSetting.count", -1) do
      delete router_setting_url(@router_setting)
    end

    assert_redirected_to router_settings_url
  end
end
