require "test_helper"

class OnusControllerTest < ActionDispatch::IntegrationTest
  setup do
    @onu = onus(:one)
  end

  test "should get index" do
    get onus_url
    assert_response :success
  end

  test "should get new" do
    get new_onu_url
    assert_response :success
  end

  test "should create onu" do
    assert_difference("Onu.count") do
      post onus_url, params: { onu: { account_id: @onu.account_id, last_boot: @onu.last_boot, last_inform: @onu.last_inform, manufacturer: @onu.manufacturer, onu_id: @onu.onu_id, oui: @onu.oui, product_class: @onu.product_class, serial_number: @onu.serial_number, status: @onu.status } }
    end

    assert_redirected_to onu_url(Onu.last)
  end

  test "should show onu" do
    get onu_url(@onu)
    assert_response :success
  end

  test "should get edit" do
    get edit_onu_url(@onu)
    assert_response :success
  end

  test "should update onu" do
    patch onu_url(@onu), params: { onu: { account_id: @onu.account_id, last_boot: @onu.last_boot, last_inform: @onu.last_inform, manufacturer: @onu.manufacturer, onu_id: @onu.onu_id, oui: @onu.oui, product_class: @onu.product_class, serial_number: @onu.serial_number, status: @onu.status } }
    assert_redirected_to onu_url(@onu)
  end

  test "should destroy onu" do
    assert_difference("Onu.count", -1) do
      delete onu_url(@onu)
    end

    assert_redirected_to onus_url
  end
end
