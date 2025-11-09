require "test_helper"

class AdSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ad_setting = ad_settings(:one)
  end

  test "should get index" do
    get ad_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_ad_setting_url
    assert_response :success
  end

  test "should create ad_setting" do
    assert_difference("AdSetting.count") do
      post ad_settings_url, params: { ad_setting: { account_id: @ad_setting.account_id, enabled: @ad_setting.enabled, to_left: @ad_setting.to_left, to_right: @ad_setting.to_right, to_top: @ad_setting.to_top } }
    end

    assert_redirected_to ad_setting_url(AdSetting.last)
  end

  test "should show ad_setting" do
    get ad_setting_url(@ad_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_ad_setting_url(@ad_setting)
    assert_response :success
  end

  test "should update ad_setting" do
    patch ad_setting_url(@ad_setting), params: { ad_setting: { account_id: @ad_setting.account_id, enabled: @ad_setting.enabled, to_left: @ad_setting.to_left, to_right: @ad_setting.to_right, to_top: @ad_setting.to_top } }
    assert_redirected_to ad_setting_url(@ad_setting)
  end

  test "should destroy ad_setting" do
    assert_difference("AdSetting.count", -1) do
      delete ad_setting_url(@ad_setting)
    end

    assert_redirected_to ad_settings_url
  end
end
