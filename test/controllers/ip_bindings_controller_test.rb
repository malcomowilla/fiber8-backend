require "test_helper"

class IpBindingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ip_binding = ip_bindings(:one)
  end

  test "should get index" do
    get ip_bindings_url
    assert_response :success
  end

  test "should get new" do
    get new_ip_binding_url
    assert_response :success
  end

  test "should create ip_binding" do
    assert_difference("IpBinding.count") do
      post ip_bindings_url, params: { ip_binding: { account_id: @ip_binding.account_id, device_type: @ip_binding.device_type, expiry: @ip_binding.expiry, ip: @ip_binding.ip, mac: @ip_binding.mac, name: @ip_binding.name, package: @ip_binding.package, router: @ip_binding.router, router_id: @ip_binding.router_id } }
    end

    assert_redirected_to ip_binding_url(IpBinding.last)
  end

  test "should show ip_binding" do
    get ip_binding_url(@ip_binding)
    assert_response :success
  end

  test "should get edit" do
    get edit_ip_binding_url(@ip_binding)
    assert_response :success
  end

  test "should update ip_binding" do
    patch ip_binding_url(@ip_binding), params: { ip_binding: { account_id: @ip_binding.account_id, device_type: @ip_binding.device_type, expiry: @ip_binding.expiry, ip: @ip_binding.ip, mac: @ip_binding.mac, name: @ip_binding.name, package: @ip_binding.package, router: @ip_binding.router, router_id: @ip_binding.router_id } }
    assert_redirected_to ip_binding_url(@ip_binding)
  end

  test "should destroy ip_binding" do
    assert_difference("IpBinding.count", -1) do
      delete ip_binding_url(@ip_binding)
    end

    assert_redirected_to ip_bindings_url
  end
end
