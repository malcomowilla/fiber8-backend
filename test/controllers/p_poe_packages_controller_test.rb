require "test_helper"

class PPoePackagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @p_poe_package = p_poe_packages(:one)
  end

  test "should get index" do
    get p_poe_packages_url
    assert_response :success
  end

  test "should get new" do
    get new_p_poe_package_url
    assert_response :success
  end

  test "should create p_poe_package" do
    assert_difference("PPoePackage.count") do
      post p_poe_packages_url, params: { p_poe_package: { download_limit: @p_poe_package.download_limit, name: @p_poe_package.name, price: @p_poe_package.price, upload_limit: @p_poe_package.upload_limit, validity: @p_poe_package.validity } }
    end

    assert_redirected_to p_poe_package_url(PPoePackage.last)
  end

  test "should show p_poe_package" do
    get p_poe_package_url(@p_poe_package)
    assert_response :success
  end

  test "should get edit" do
    get edit_p_poe_package_url(@p_poe_package)
    assert_response :success
  end

  test "should update p_poe_package" do
    patch p_poe_package_url(@p_poe_package), params: { p_poe_package: { download_limit: @p_poe_package.download_limit, name: @p_poe_package.name, price: @p_poe_package.price, upload_limit: @p_poe_package.upload_limit, validity: @p_poe_package.validity } }
    assert_redirected_to p_poe_package_url(@p_poe_package)
  end

  test "should destroy p_poe_package" do
    assert_difference("PPoePackage.count", -1) do
      delete p_poe_package_url(@p_poe_package)
    end

    assert_redirected_to p_poe_packages_url
  end
end
