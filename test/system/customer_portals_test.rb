require "application_system_test_case"

class CustomerPortalsTest < ApplicationSystemTestCase
  setup do
    @customer_portal = customer_portals(:one)
  end

  test "visiting the index" do
    visit customer_portals_url
    assert_selector "h1", text: "Customer portals"
  end

  test "should create customer portal" do
    visit customer_portals_url
    click_on "New customer portal"

    fill_in "Account", with: @customer_portal.account_id
    fill_in "Password", with: @customer_portal.password
    fill_in "Username", with: @customer_portal.username
    click_on "Create Customer portal"

    assert_text "Customer portal was successfully created"
    click_on "Back"
  end

  test "should update Customer portal" do
    visit customer_portal_url(@customer_portal)
    click_on "Edit this customer portal", match: :first

    fill_in "Account", with: @customer_portal.account_id
    fill_in "Password", with: @customer_portal.password
    fill_in "Username", with: @customer_portal.username
    click_on "Update Customer portal"

    assert_text "Customer portal was successfully updated"
    click_on "Back"
  end

  test "should destroy Customer portal" do
    visit customer_portal_url(@customer_portal)
    click_on "Destroy this customer portal", match: :first

    assert_text "Customer portal was successfully destroyed"
  end
end
