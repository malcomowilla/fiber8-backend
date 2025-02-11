require "test_helper"

class TicketSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get ticket_settings_index_url
    assert_response :success
  end

  test "should get create" do
    get ticket_settings_create_url
    assert_response :success
  end

  test "should get allow_get_ticket_settings" do
    get ticket_settings_allow_get_ticket_settings_url
    assert_response :success
  end
end
