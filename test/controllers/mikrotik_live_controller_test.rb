require "test_helper"

class MikrotikLiveControllerTest < ActionDispatch::IntegrationTest
  test "should get mikrotik" do
    get mikrotik_live_mikrotik_url
    assert_response :success
  end
end
