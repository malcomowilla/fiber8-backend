require "test_helper"

class HotspotPackagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_package = hotspot_packages(:one)
  end

  test "should get index" do
    get hotspot_packages_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_package_url
    assert_response :success
  end

  test "should create hotspot_package" do
    assert_difference("HotspotPackage.count") do
      post hotspot_packages_url, params: { hotspot_package: { account_id: @hotspot_package.account_id, download_burst_limit: @hotspot_package.download_burst_limit, download_limit: @hotspot_package.download_limit, name: @hotspot_package.name, price: @hotspot_package.price, rx_rate_limit: @hotspot_package.rx_rate_limit, tx_rate_limit: @hotspot_package.tx_rate_limit, upload_burst_limitmikrotik_id: @hotspot_package.upload_burst_limitmikrotik_id, upload_limit: @hotspot_package.upload_limit, validity: @hotspot_package.validity, validity_period_units: @hotspot_package.validity_period_units } }
    end

    assert_redirected_to hotspot_package_url(HotspotPackage.last)
  end

  test "should show hotspot_package" do
    get hotspot_package_url(@hotspot_package)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_package_url(@hotspot_package)
    assert_response :success
  end

  test "should update hotspot_package" do
    patch hotspot_package_url(@hotspot_package), params: { hotspot_package: { account_id: @hotspot_package.account_id, download_burst_limit: @hotspot_package.download_burst_limit, download_limit: @hotspot_package.download_limit, name: @hotspot_package.name, price: @hotspot_package.price, rx_rate_limit: @hotspot_package.rx_rate_limit, tx_rate_limit: @hotspot_package.tx_rate_limit, upload_burst_limitmikrotik_id: @hotspot_package.upload_burst_limitmikrotik_id, upload_limit: @hotspot_package.upload_limit, validity: @hotspot_package.validity, validity_period_units: @hotspot_package.validity_period_units } }
    assert_redirected_to hotspot_package_url(@hotspot_package)
  end

  test "should destroy hotspot_package" do
    assert_difference("HotspotPackage.count", -1) do
      delete hotspot_package_url(@hotspot_package)
    end

    assert_redirected_to hotspot_packages_url
  end
end
