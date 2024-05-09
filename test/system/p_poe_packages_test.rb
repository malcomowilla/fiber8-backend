require "application_system_test_case"

class PPoePackagesTest < ApplicationSystemTestCase
  setup do
    @p_poe_package = p_poe_packages(:one)
  end

  test "visiting the index" do
    visit p_poe_packages_url
    assert_selector "h1", text: "P poe packages"
  end

  test "should create p poe package" do
    visit p_poe_packages_url
    click_on "New p poe package"

    fill_in "Download limit", with: @p_poe_package.download_limit
    fill_in "Name", with: @p_poe_package.name
    fill_in "Price", with: @p_poe_package.price
    fill_in "Upload limit", with: @p_poe_package.upload_limit
    fill_in "Validity", with: @p_poe_package.validity
    click_on "Create P poe package"

    assert_text "P poe package was successfully created"
    click_on "Back"
  end

  test "should update P poe package" do
    visit p_poe_package_url(@p_poe_package)
    click_on "Edit this p poe package", match: :first

    fill_in "Download limit", with: @p_poe_package.download_limit
    fill_in "Name", with: @p_poe_package.name
    fill_in "Price", with: @p_poe_package.price
    fill_in "Upload limit", with: @p_poe_package.upload_limit
    fill_in "Validity", with: @p_poe_package.validity
    click_on "Update P poe package"

    assert_text "P poe package was successfully updated"
    click_on "Back"
  end

  test "should destroy P poe package" do
    visit p_poe_package_url(@p_poe_package)
    click_on "Destroy this p poe package", match: :first

    assert_text "P poe package was successfully destroyed"
  end
end
