require "test_helper"

class IpPoolsControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get ip_pools_create_url
    assert_response :success
  end

  test "should get index" do
    get ip_pools_index_url
    assert_response :success
  end
end
