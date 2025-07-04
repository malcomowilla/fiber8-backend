require "test_helper"

class ActivtyLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @activty_log = activty_logs(:one)
  end

  test "should get index" do
    get activty_logs_url
    assert_response :success
  end

  test "should get new" do
    get new_activty_log_url
    assert_response :success
  end

  test "should create activty_log" do
    assert_difference("ActivtyLog.count") do
      post activty_logs_url, params: { activty_log: { account_id: @activty_log.account_id, action: @activty_log.action, date: @activty_log.date, description: @activty_log.description, subject: @activty_log.subject, user: @activty_log.user } }
    end

    assert_redirected_to activty_log_url(ActivtyLog.last)
  end

  test "should show activty_log" do
    get activty_log_url(@activty_log)
    assert_response :success
  end

  test "should get edit" do
    get edit_activty_log_url(@activty_log)
    assert_response :success
  end

  test "should update activty_log" do
    patch activty_log_url(@activty_log), params: { activty_log: { account_id: @activty_log.account_id, action: @activty_log.action, date: @activty_log.date, description: @activty_log.description, subject: @activty_log.subject, user: @activty_log.user } }
    assert_redirected_to activty_log_url(@activty_log)
  end

  test "should destroy activty_log" do
    assert_difference("ActivtyLog.count", -1) do
      delete activty_log_url(@activty_log)
    end

    assert_redirected_to activty_logs_url
  end
end
