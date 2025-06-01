require "test_helper"

class ChangeLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @change_log = change_logs(:one)
  end

  test "should get index" do
    get change_logs_url
    assert_response :success
  end

  test "should get new" do
    get new_change_log_url
    assert_response :success
  end

  test "should create change_log" do
    assert_difference("ChangeLog.count") do
      post change_logs_url, params: { change_log: { change_title: @change_log.change_title, system_changes: @change_log.system_changes, version: @change_log.version } }
    end

    assert_redirected_to change_log_url(ChangeLog.last)
  end

  test "should show change_log" do
    get change_log_url(@change_log)
    assert_response :success
  end

  test "should get edit" do
    get edit_change_log_url(@change_log)
    assert_response :success
  end

  test "should update change_log" do
    patch change_log_url(@change_log), params: { change_log: { change_title: @change_log.change_title, system_changes: @change_log.system_changes, version: @change_log.version } }
    assert_redirected_to change_log_url(@change_log)
  end

  test "should destroy change_log" do
    assert_difference("ChangeLog.count", -1) do
      delete change_log_url(@change_log)
    end

    assert_redirected_to change_logs_url
  end
end
