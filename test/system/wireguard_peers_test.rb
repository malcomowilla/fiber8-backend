require "application_system_test_case"

class WireguardPeersTest < ApplicationSystemTestCase
  setup do
    @wireguard_peer = wireguard_peers(:one)
  end

  test "visiting the index" do
    visit wireguard_peers_url
    assert_selector "h1", text: "Wireguard peers"
  end

  test "should create wireguard peer" do
    visit wireguard_peers_url
    click_on "New wireguard peer"

    fill_in "Allowed ips", with: @wireguard_peer.allowed_ips
    fill_in "Persistent keepalive", with: @wireguard_peer.persistent_keepalive
    fill_in "Public key", with: @wireguard_peer.public_key
    click_on "Create Wireguard peer"

    assert_text "Wireguard peer was successfully created"
    click_on "Back"
  end

  test "should update Wireguard peer" do
    visit wireguard_peer_url(@wireguard_peer)
    click_on "Edit this wireguard peer", match: :first

    fill_in "Allowed ips", with: @wireguard_peer.allowed_ips
    fill_in "Persistent keepalive", with: @wireguard_peer.persistent_keepalive
    fill_in "Public key", with: @wireguard_peer.public_key
    click_on "Update Wireguard peer"

    assert_text "Wireguard peer was successfully updated"
    click_on "Back"
  end

  test "should destroy Wireguard peer" do
    visit wireguard_peer_url(@wireguard_peer)
    click_on "Destroy this wireguard peer", match: :first

    assert_text "Wireguard peer was successfully destroyed"
  end
end
