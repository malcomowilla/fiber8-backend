require "application_system_test_case"

class OnusTest < ApplicationSystemTestCase
  setup do
    @onu = onus(:one)
  end

  test "visiting the index" do
    visit onus_url
    assert_selector "h1", text: "Onus"
  end

  test "should create onu" do
    visit onus_url
    click_on "New onu"

    fill_in "Account", with: @onu.account_id
    fill_in "Last boot", with: @onu.last_boot
    fill_in "Last inform", with: @onu.last_inform
    fill_in "Manufacturer", with: @onu.manufacturer
    fill_in "Onu", with: @onu.onu_id
    fill_in "Oui", with: @onu.oui
    fill_in "Product class", with: @onu.product_class
    fill_in "Serial number", with: @onu.serial_number
    fill_in "Status", with: @onu.status
    click_on "Create Onu"

    assert_text "Onu was successfully created"
    click_on "Back"
  end

  test "should update Onu" do
    visit onu_url(@onu)
    click_on "Edit this onu", match: :first

    fill_in "Account", with: @onu.account_id
    fill_in "Last boot", with: @onu.last_boot
    fill_in "Last inform", with: @onu.last_inform
    fill_in "Manufacturer", with: @onu.manufacturer
    fill_in "Onu", with: @onu.onu_id
    fill_in "Oui", with: @onu.oui
    fill_in "Product class", with: @onu.product_class
    fill_in "Serial number", with: @onu.serial_number
    fill_in "Status", with: @onu.status
    click_on "Update Onu"

    assert_text "Onu was successfully updated"
    click_on "Back"
  end

  test "should destroy Onu" do
    visit onu_url(@onu)
    click_on "Destroy this onu", match: :first

    assert_text "Onu was successfully destroyed"
  end
end
