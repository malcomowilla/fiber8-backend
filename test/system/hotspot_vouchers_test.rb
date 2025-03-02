require "application_system_test_case"

class HotspotVouchersTest < ApplicationSystemTestCase
  setup do
    @hotspot_voucher = hotspot_vouchers(:one)
  end

  test "visiting the index" do
    visit hotspot_vouchers_url
    assert_selector "h1", text: "Hotspot vouchers"
  end

  test "should create hotspot voucher" do
    visit hotspot_vouchers_url
    click_on "New hotspot voucher"

    fill_in "Expiration", with: @hotspot_voucher.expiration
    fill_in "Phone", with: @hotspot_voucher.phone
    fill_in "Speed limit", with: @hotspot_voucher.speed_limit
    fill_in "Status", with: @hotspot_voucher.status
    fill_in "Voucher", with: @hotspot_voucher.voucher
    click_on "Create Hotspot voucher"

    assert_text "Hotspot voucher was successfully created"
    click_on "Back"
  end

  test "should update Hotspot voucher" do
    visit hotspot_voucher_url(@hotspot_voucher)
    click_on "Edit this hotspot voucher", match: :first

    fill_in "Expiration", with: @hotspot_voucher.expiration.to_s
    fill_in "Phone", with: @hotspot_voucher.phone
    fill_in "Speed limit", with: @hotspot_voucher.speed_limit
    fill_in "Status", with: @hotspot_voucher.status
    fill_in "Voucher", with: @hotspot_voucher.voucher
    click_on "Update Hotspot voucher"

    assert_text "Hotspot voucher was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot voucher" do
    visit hotspot_voucher_url(@hotspot_voucher)
    click_on "Destroy this hotspot voucher", match: :first

    assert_text "Hotspot voucher was successfully destroyed"
  end
end
