require "test_helper"

class HotspotVouchersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_voucher = hotspot_vouchers(:one)
  end

  test "should get index" do
    get hotspot_vouchers_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_voucher_url
    assert_response :success
  end

  test "should create hotspot_voucher" do
    assert_difference("HotspotVoucher.count") do
      post hotspot_vouchers_url, params: { hotspot_voucher: { expiration: @hotspot_voucher.expiration, phone: @hotspot_voucher.phone, speed_limit: @hotspot_voucher.speed_limit, status: @hotspot_voucher.status, voucher: @hotspot_voucher.voucher } }
    end

    assert_redirected_to hotspot_voucher_url(HotspotVoucher.last)
  end

  test "should show hotspot_voucher" do
    get hotspot_voucher_url(@hotspot_voucher)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_voucher_url(@hotspot_voucher)
    assert_response :success
  end

  test "should update hotspot_voucher" do
    patch hotspot_voucher_url(@hotspot_voucher), params: { hotspot_voucher: { expiration: @hotspot_voucher.expiration, phone: @hotspot_voucher.phone, speed_limit: @hotspot_voucher.speed_limit, status: @hotspot_voucher.status, voucher: @hotspot_voucher.voucher } }
    assert_redirected_to hotspot_voucher_url(@hotspot_voucher)
  end

  test "should destroy hotspot_voucher" do
    assert_difference("HotspotVoucher.count", -1) do
      delete hotspot_voucher_url(@hotspot_voucher)
    end

    assert_redirected_to hotspot_vouchers_url
  end
end
