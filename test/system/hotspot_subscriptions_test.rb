require "application_system_test_case"

class HotspotSubscriptionsTest < ApplicationSystemTestCase
  setup do
    @hotspot_subscription = hotspot_subscriptions(:one)
  end

  test "visiting the index" do
    visit hotspot_subscriptions_url
    assert_selector "h1", text: "Hotspot subscriptions"
  end

  test "should create hotspot subscription" do
    visit hotspot_subscriptions_url
    click_on "New hotspot subscription"

    fill_in "Account", with: @hotspot_subscription.account_id
    fill_in "Download", with: @hotspot_subscription.download
    fill_in "Ip address", with: @hotspot_subscription.ip_address
    fill_in "Start time", with: @hotspot_subscription.start_time
    fill_in "Up time", with: @hotspot_subscription.up_time
    fill_in "Upload", with: @hotspot_subscription.upload
    fill_in "Voucher", with: @hotspot_subscription.voucher
    click_on "Create Hotspot subscription"

    assert_text "Hotspot subscription was successfully created"
    click_on "Back"
  end

  test "should update Hotspot subscription" do
    visit hotspot_subscription_url(@hotspot_subscription)
    click_on "Edit this hotspot subscription", match: :first

    fill_in "Account", with: @hotspot_subscription.account_id
    fill_in "Download", with: @hotspot_subscription.download
    fill_in "Ip address", with: @hotspot_subscription.ip_address
    fill_in "Start time", with: @hotspot_subscription.start_time
    fill_in "Up time", with: @hotspot_subscription.up_time
    fill_in "Upload", with: @hotspot_subscription.upload
    fill_in "Voucher", with: @hotspot_subscription.voucher
    click_on "Update Hotspot subscription"

    assert_text "Hotspot subscription was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot subscription" do
    visit hotspot_subscription_url(@hotspot_subscription)
    click_on "Destroy this hotspot subscription", match: :first

    assert_text "Hotspot subscription was successfully destroyed"
  end
end
