require "test_helper"

class SystemAdminSmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_admin_sm = system_admin_sms(:one)
  end

  test "should get index" do
    get system_admin_sms_url
    assert_response :success
  end

  test "should get new" do
    get new_system_admin_sm_url
    assert_response :success
  end

  test "should create system_admin_sm" do
    assert_difference("SystemAdminSm.count") do
      post system_admin_sms_url, params: { system_admin_sm: { date: @system_admin_sm.date, message: @system_admin_sm.message, status: @system_admin_sm.status, system_user: @system_admin_sm.system_user, user: @system_admin_sm.user } }
    end

    assert_redirected_to system_admin_sm_url(SystemAdminSm.last)
  end

  test "should show system_admin_sm" do
    get system_admin_sm_url(@system_admin_sm)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_admin_sm_url(@system_admin_sm)
    assert_response :success
  end

  test "should update system_admin_sm" do
    patch system_admin_sm_url(@system_admin_sm), params: { system_admin_sm: { date: @system_admin_sm.date, message: @system_admin_sm.message, status: @system_admin_sm.status, system_user: @system_admin_sm.system_user, user: @system_admin_sm.user } }
    assert_redirected_to system_admin_sm_url(@system_admin_sm)
  end

  test "should destroy system_admin_sm" do
    assert_difference("SystemAdminSm.count", -1) do
      delete system_admin_sm_url(@system_admin_sm)
    end

    assert_redirected_to system_admin_sms_url
  end
end
