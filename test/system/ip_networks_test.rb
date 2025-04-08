require "application_system_test_case"

class IpNetworksTest < ApplicationSystemTestCase
  setup do
    @ip_network = ip_networks(:one)
  end

  test "visiting the index" do
    visit ip_networks_url
    assert_selector "h1", text: "Ip networks"
  end

  test "should create ip network" do
    visit ip_networks_url
    click_on "New ip network"

    fill_in "Account", with: @ip_network.account_id
    fill_in "Ip adress", with: @ip_network.ip_adress
    fill_in "Network", with: @ip_network.network
    fill_in "Title", with: @ip_network.title
    click_on "Create Ip network"

    assert_text "Ip network was successfully created"
    click_on "Back"
  end

  test "should update Ip network" do
    visit ip_network_url(@ip_network)
    click_on "Edit this ip network", match: :first

    fill_in "Account", with: @ip_network.account_id
    fill_in "Ip adress", with: @ip_network.ip_adress
    fill_in "Network", with: @ip_network.network
    fill_in "Title", with: @ip_network.title
    click_on "Update Ip network"

    assert_text "Ip network was successfully updated"
    click_on "Back"
  end

  test "should destroy Ip network" do
    visit ip_network_url(@ip_network)
    click_on "Destroy this ip network", match: :first

    assert_text "Ip network was successfully destroyed"
  end
end
