require "test_helper"

class PackagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @package = packages(:one)
  end

  test "should get index" do
    get packages_url
    assert_response :success
  end

  test "should get new" do
    get new_package_url
    assert_response :success
  end

  test "should create package" do
    assert_difference("Package.count") do
      post packages_url, params: { package: { account_id: @package.account_id, download_burst_limit: @package.download_burst_limit, download_limit: @package.download_limit, mikrotik_id: @package.mikrotik_id, name: @package.name, price: @package.price, rx_rate_limit: @package.rx_rate_limit, tx_rate_limit: @package.tx_rate_limit, upload_burst_limit: @package.upload_burst_limit, upload_limit: @package.upload_limit, validity: @package.validity, validity_period_units: @package.validity_period_units } }
    end

    assert_redirected_to package_url(Package.last)
  end

  test "should show package" do
    get package_url(@package)
    assert_response :success
  end

  test "should get edit" do
    get edit_package_url(@package)
    assert_response :success
  end

  test "should update package" do
    patch package_url(@package), params: { package: { account_id: @package.account_id, download_burst_limit: @package.download_burst_limit, download_limit: @package.download_limit, mikrotik_id: @package.mikrotik_id, name: @package.name, price: @package.price, rx_rate_limit: @package.rx_rate_limit, tx_rate_limit: @package.tx_rate_limit, upload_burst_limit: @package.upload_burst_limit, upload_limit: @package.upload_limit, validity: @package.validity, validity_period_units: @package.validity_period_units } }
    assert_redirected_to package_url(@package)
  end

  test "should destroy package" do
    assert_difference("Package.count", -1) do
      delete package_url(@package)
    end

    assert_redirected_to packages_url
  end
end
