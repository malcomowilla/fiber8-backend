require "application_system_test_case"

class HotspotPackagesTest < ApplicationSystemTestCase
  setup do
    @hotspot_package = hotspot_packages(:one)
  end

  test "visiting the index" do
    visit hotspot_packages_url
    assert_selector "h1", text: "Hotspot packages"
  end

  test "should create hotspot package" do
    visit hotspot_packages_url
    click_on "New hotspot package"

    fill_in "Account", with: @hotspot_package.account_id
    fill_in "Download burst limit", with: @hotspot_package.download_burst_limit
    fill_in "Download limit", with: @hotspot_package.download_limit
    fill_in "Name", with: @hotspot_package.name
    fill_in "Price", with: @hotspot_package.price
    fill_in "Rx rate limit", with: @hotspot_package.rx_rate_limit
    fill_in "Tx rate limit", with: @hotspot_package.tx_rate_limit
    fill_in "Upload burst limitmikrotik", with: @hotspot_package.upload_burst_limitmikrotik_id
    fill_in "Upload limit", with: @hotspot_package.upload_limit
    fill_in "Validity", with: @hotspot_package.validity
    fill_in "Validity period units", with: @hotspot_package.validity_period_units
    click_on "Create Hotspot package"

    assert_text "Hotspot package was successfully created"
    click_on "Back"
  end

  test "should update Hotspot package" do
    visit hotspot_package_url(@hotspot_package)
    click_on "Edit this hotspot package", match: :first

    fill_in "Account", with: @hotspot_package.account_id
    fill_in "Download burst limit", with: @hotspot_package.download_burst_limit
    fill_in "Download limit", with: @hotspot_package.download_limit
    fill_in "Name", with: @hotspot_package.name
    fill_in "Price", with: @hotspot_package.price
    fill_in "Rx rate limit", with: @hotspot_package.rx_rate_limit
    fill_in "Tx rate limit", with: @hotspot_package.tx_rate_limit
    fill_in "Upload burst limitmikrotik", with: @hotspot_package.upload_burst_limitmikrotik_id
    fill_in "Upload limit", with: @hotspot_package.upload_limit
    fill_in "Validity", with: @hotspot_package.validity
    fill_in "Validity period units", with: @hotspot_package.validity_period_units
    click_on "Update Hotspot package"

    assert_text "Hotspot package was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot package" do
    visit hotspot_package_url(@hotspot_package)
    click_on "Destroy this hotspot package", match: :first

    assert_text "Hotspot package was successfully destroyed"
  end
end
