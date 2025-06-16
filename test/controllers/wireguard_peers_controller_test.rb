require "test_helper"

class WireguardPeersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @wireguard_peer = wireguard_peers(:one)
  end

  test "should get index" do
    get wireguard_peers_url
    assert_response :success
  end

  test "should get new" do
    get new_wireguard_peer_url
    assert_response :success
  end

  test "should create wireguard_peer" do
    assert_difference("WireguardPeer.count") do
      post wireguard_peers_url, params: { wireguard_peer: { allowed_ips: @wireguard_peer.allowed_ips, persistent_keepalive: @wireguard_peer.persistent_keepalive, public_key: @wireguard_peer.public_key } }
    end

    assert_redirected_to wireguard_peer_url(WireguardPeer.last)
  end

  test "should show wireguard_peer" do
    get wireguard_peer_url(@wireguard_peer)
    assert_response :success
  end

  test "should get edit" do
    get edit_wireguard_peer_url(@wireguard_peer)
    assert_response :success
  end

  test "should update wireguard_peer" do
    patch wireguard_peer_url(@wireguard_peer), params: { wireguard_peer: { allowed_ips: @wireguard_peer.allowed_ips, persistent_keepalive: @wireguard_peer.persistent_keepalive, public_key: @wireguard_peer.public_key } }
    assert_redirected_to wireguard_peer_url(@wireguard_peer)
  end

  test "should destroy wireguard_peer" do
    assert_difference("WireguardPeer.count", -1) do
      delete wireguard_peer_url(@wireguard_peer)
    end

    assert_redirected_to wireguard_peers_url
  end
end
