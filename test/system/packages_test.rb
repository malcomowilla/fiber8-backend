require "application_system_test_case"

class PackagesTest < ApplicationSystemTestCase
  setup do
    @package = packages(:one)
  end

  test "visiting the index" do
    visit packages_url
    assert_selector "h1", text: "Packages"
  end

  test "should create package" do
    visit packages_url
    click_on "New package"

    fill_in "Account", with: @package.account_id
    fill_in "Download burst limit", with: @package.download_burst_limit
    fill_in "Download limit", with: @package.download_limit
    fill_in "Mikrotik", with: @package.mikrotik_id
    fill_in "Name", with: @package.name
    fill_in "Price", with: @package.price
    fill_in "Rx rate limit", with: @package.rx_rate_limit
    fill_in "Tx rate limit", with: @package.tx_rate_limit
    fill_in "Upload burst limit", with: @package.upload_burst_limit
    fill_in "Upload limit", with: @package.upload_limit
    fill_in "Validity", with: @package.validity
    fill_in "Validity period units", with: @package.validity_period_units
    click_on "Create Package"

    assert_text "Package was successfully created"
    click_on "Back"
  end

  test "should update Package" do
    visit package_url(@package)
    click_on "Edit this package", match: :first

    fill_in "Account", with: @package.account_id
    fill_in "Download burst limit", with: @package.download_burst_limit
    fill_in "Download limit", with: @package.download_limit
    fill_in "Mikrotik", with: @package.mikrotik_id
    fill_in "Name", with: @package.name
    fill_in "Price", with: @package.price
    fill_in "Rx rate limit", with: @package.rx_rate_limit
    fill_in "Tx rate limit", with: @package.tx_rate_limit
    fill_in "Upload burst limit", with: @package.upload_burst_limit
    fill_in "Upload limit", with: @package.upload_limit
    fill_in "Validity", with: @package.validity
    fill_in "Validity period units", with: @package.validity_period_units
    click_on "Update Package"

    assert_text "Package was successfully updated"
    click_on "Back"
  end

  test "should destroy Package" do
    visit package_url(@package)
    click_on "Destroy this package", match: :first

    assert_text "Package was successfully destroyed"
  end
end
