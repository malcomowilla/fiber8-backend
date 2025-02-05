require "test_helper"

class SmsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sm = sms(:one)
  end

  test "should get index" do
    get sms_url
    assert_response :success
  end

  test "should get new" do
    get new_sm_url
    assert_response :success
  end

  test "should create sm" do
    assert_difference("Sm.count") do
      post sms_url, params: { sm: { account_id: @sm.account_id, admin_user: @sm.admin_user, date: @sm.date, message: @sm.message, status: @sm.status, system_user: @sm.system_user, user: @sm.user } }
    end

    assert_redirected_to sm_url(Sm.last)
  end

  test "should show sm" do
    get sm_url(@sm)
    assert_response :success
  end

  test "should get edit" do
    get edit_sm_url(@sm)
    assert_response :success
  end

  test "should update sm" do
    patch sm_url(@sm), params: { sm: { account_id: @sm.account_id, admin_user: @sm.admin_user, date: @sm.date, message: @sm.message, status: @sm.status, system_user: @sm.system_user, user: @sm.user } }
    assert_redirected_to sm_url(@sm)
  end

  test "should destroy sm" do
    assert_difference("Sm.count", -1) do
      delete sm_url(@sm)
    end

    assert_redirected_to sms_url
  end
end
