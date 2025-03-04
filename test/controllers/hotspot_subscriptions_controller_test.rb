require "test_helper"

class HotspotSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_subscription = hotspot_subscriptions(:one)
  end

  test "should get index" do
    get hotspot_subscriptions_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_subscription_url
    assert_response :success
  end

  test "should create hotspot_subscription" do
    assert_difference("HotspotSubscription.count") do
      post hotspot_subscriptions_url, params: { hotspot_subscription: { account_id: @hotspot_subscription.account_id, download: @hotspot_subscription.download, ip_address: @hotspot_subscription.ip_address, start_time: @hotspot_subscription.start_time, up_time: @hotspot_subscription.up_time, upload: @hotspot_subscription.upload, voucher: @hotspot_subscription.voucher } }
    end

    assert_redirected_to hotspot_subscription_url(HotspotSubscription.last)
  end

  test "should show hotspot_subscription" do
    get hotspot_subscription_url(@hotspot_subscription)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_subscription_url(@hotspot_subscription)
    assert_response :success
  end

  test "should update hotspot_subscription" do
    patch hotspot_subscription_url(@hotspot_subscription), params: { hotspot_subscription: { account_id: @hotspot_subscription.account_id, download: @hotspot_subscription.download, ip_address: @hotspot_subscription.ip_address, start_time: @hotspot_subscription.start_time, up_time: @hotspot_subscription.up_time, upload: @hotspot_subscription.upload, voucher: @hotspot_subscription.voucher } }
    assert_redirected_to hotspot_subscription_url(@hotspot_subscription)
  end

  test "should destroy hotspot_subscription" do
    assert_difference("HotspotSubscription.count", -1) do
      delete hotspot_subscription_url(@hotspot_subscription)
    end

    assert_redirected_to hotspot_subscriptions_url
  end
end
