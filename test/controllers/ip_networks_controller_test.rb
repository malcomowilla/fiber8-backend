require "test_helper"

class IpNetworksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ip_network = ip_networks(:one)
  end

  test "should get index" do
    get ip_networks_url
    assert_response :success
  end

  test "should get new" do
    get new_ip_network_url
    assert_response :success
  end

  test "should create ip_network" do
    assert_difference("IpNetwork.count") do
      post ip_networks_url, params: { ip_network: { account_id: @ip_network.account_id, ip_adress: @ip_network.ip_adress, network: @ip_network.network, title: @ip_network.title } }
    end

    assert_redirected_to ip_network_url(IpNetwork.last)
  end

  test "should show ip_network" do
    get ip_network_url(@ip_network)
    assert_response :success
  end

  test "should get edit" do
    get edit_ip_network_url(@ip_network)
    assert_response :success
  end

  test "should update ip_network" do
    patch ip_network_url(@ip_network), params: { ip_network: { account_id: @ip_network.account_id, ip_adress: @ip_network.ip_adress, network: @ip_network.network, title: @ip_network.title } }
    assert_redirected_to ip_network_url(@ip_network)
  end

  test "should destroy ip_network" do
    assert_difference("IpNetwork.count", -1) do
      delete ip_network_url(@ip_network)
    end

    assert_redirected_to ip_networks_url
  end
end
