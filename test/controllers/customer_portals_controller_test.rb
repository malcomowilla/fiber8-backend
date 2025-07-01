require "test_helper"

class CustomerPortalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @customer_portal = customer_portals(:one)
  end

  test "should get index" do
    get customer_portals_url
    assert_response :success
  end

  test "should get new" do
    get new_customer_portal_url
    assert_response :success
  end

  test "should create customer_portal" do
    assert_difference("CustomerPortal.count") do
      post customer_portals_url, params: { customer_portal: { account_id: @customer_portal.account_id, password: @customer_portal.password, username: @customer_portal.username } }
    end

    assert_redirected_to customer_portal_url(CustomerPortal.last)
  end

  test "should show customer_portal" do
    get customer_portal_url(@customer_portal)
    assert_response :success
  end

  test "should get edit" do
    get edit_customer_portal_url(@customer_portal)
    assert_response :success
  end

  test "should update customer_portal" do
    patch customer_portal_url(@customer_portal), params: { customer_portal: { account_id: @customer_portal.account_id, password: @customer_portal.password, username: @customer_portal.username } }
    assert_redirected_to customer_portal_url(@customer_portal)
  end

  test "should destroy customer_portal" do
    assert_difference("CustomerPortal.count", -1) do
      delete customer_portal_url(@customer_portal)
    end

    assert_redirected_to customer_portals_url
  end
end
