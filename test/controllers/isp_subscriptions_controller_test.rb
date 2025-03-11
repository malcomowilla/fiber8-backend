require "test_helper"

class IspSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @isp_subscription = isp_subscriptions(:one)
  end

  test "should get index" do
    get isp_subscriptions_url
    assert_response :success
  end

  test "should get new" do
    get new_isp_subscription_url
    assert_response :success
  end

  test "should create isp_subscription" do
    assert_difference("IspSubscription.count") do
      post isp_subscriptions_url, params: { isp_subscription: { account_id: @isp_subscription.account_id, features: @isp_subscription.features, last_payment_date: @isp_subscription.last_payment_date, next_billing_date: @isp_subscription.next_billing_date, payment_status: @isp_subscription.payment_status, plan_name: @isp_subscription.plan_name, renewal_period: @isp_subscription.renewal_period } }
    end

    assert_redirected_to isp_subscription_url(IspSubscription.last)
  end

  test "should show isp_subscription" do
    get isp_subscription_url(@isp_subscription)
    assert_response :success
  end

  test "should get edit" do
    get edit_isp_subscription_url(@isp_subscription)
    assert_response :success
  end

  test "should update isp_subscription" do
    patch isp_subscription_url(@isp_subscription), params: { isp_subscription: { account_id: @isp_subscription.account_id, features: @isp_subscription.features, last_payment_date: @isp_subscription.last_payment_date, next_billing_date: @isp_subscription.next_billing_date, payment_status: @isp_subscription.payment_status, plan_name: @isp_subscription.plan_name, renewal_period: @isp_subscription.renewal_period } }
    assert_redirected_to isp_subscription_url(@isp_subscription)
  end

  test "should destroy isp_subscription" do
    assert_difference("IspSubscription.count", -1) do
      delete isp_subscription_url(@isp_subscription)
    end

    assert_redirected_to isp_subscriptions_url
  end
end
