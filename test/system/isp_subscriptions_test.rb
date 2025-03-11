require "application_system_test_case"

class IspSubscriptionsTest < ApplicationSystemTestCase
  setup do
    @isp_subscription = isp_subscriptions(:one)
  end

  test "visiting the index" do
    visit isp_subscriptions_url
    assert_selector "h1", text: "Isp subscriptions"
  end

  test "should create isp subscription" do
    visit isp_subscriptions_url
    click_on "New isp subscription"

    fill_in "Account", with: @isp_subscription.account_id
    fill_in "Features", with: @isp_subscription.features
    fill_in "Last payment date", with: @isp_subscription.last_payment_date
    fill_in "Next billing date", with: @isp_subscription.next_billing_date
    fill_in "Payment status", with: @isp_subscription.payment_status
    fill_in "Plan name", with: @isp_subscription.plan_name
    fill_in "Renewal period", with: @isp_subscription.renewal_period
    click_on "Create Isp subscription"

    assert_text "Isp subscription was successfully created"
    click_on "Back"
  end

  test "should update Isp subscription" do
    visit isp_subscription_url(@isp_subscription)
    click_on "Edit this isp subscription", match: :first

    fill_in "Account", with: @isp_subscription.account_id
    fill_in "Features", with: @isp_subscription.features
    fill_in "Last payment date", with: @isp_subscription.last_payment_date.to_s
    fill_in "Next billing date", with: @isp_subscription.next_billing_date.to_s
    fill_in "Payment status", with: @isp_subscription.payment_status
    fill_in "Plan name", with: @isp_subscription.plan_name
    fill_in "Renewal period", with: @isp_subscription.renewal_period
    click_on "Update Isp subscription"

    assert_text "Isp subscription was successfully updated"
    click_on "Back"
  end

  test "should destroy Isp subscription" do
    visit isp_subscription_url(@isp_subscription)
    click_on "Destroy this isp subscription", match: :first

    assert_text "Isp subscription was successfully destroyed"
  end
end
