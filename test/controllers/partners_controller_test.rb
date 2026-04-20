require "test_helper"

class PartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @partner = partners(:one)
  end

  test "should get index" do
    get partners_url
    assert_response :success
  end

  test "should get new" do
    get new_partner_url
    assert_response :success
  end

  test "should create partner" do
    assert_difference("Partner.count") do
      post partners_url, params: { partner: { account_id: @partner.account_id, account_name: @partner.account_name, account_number: @partner.account_number, bank_name: @partner.bank_name, city: @partner.city, commission_rate: @partner.commission_rate, commission_type: @partner.commission_type, country: @partner.country, email: @partner.email, fixed_amount: @partner.fixed_amount, full_name: @partner.full_name, minimum_payout: @partner.minimum_payout, mpesa_name: @partner.mpesa_name, mpesa_number: @partner.mpesa_number, notes: @partner.notes, partner_type: @partner.partner_type, payout_frequency: @partner.payout_frequency, payout_method: @partner.payout_method, phone: @partner.phone, status: @partner.status } }
    end

    assert_redirected_to partner_url(Partner.last)
  end

  test "should show partner" do
    get partner_url(@partner)
    assert_response :success
  end

  test "should get edit" do
    get edit_partner_url(@partner)
    assert_response :success
  end

  test "should update partner" do
    patch partner_url(@partner), params: { partner: { account_id: @partner.account_id, account_name: @partner.account_name, account_number: @partner.account_number, bank_name: @partner.bank_name, city: @partner.city, commission_rate: @partner.commission_rate, commission_type: @partner.commission_type, country: @partner.country, email: @partner.email, fixed_amount: @partner.fixed_amount, full_name: @partner.full_name, minimum_payout: @partner.minimum_payout, mpesa_name: @partner.mpesa_name, mpesa_number: @partner.mpesa_number, notes: @partner.notes, partner_type: @partner.partner_type, payout_frequency: @partner.payout_frequency, payout_method: @partner.payout_method, phone: @partner.phone, status: @partner.status } }
    assert_redirected_to partner_url(@partner)
  end

  test "should destroy partner" do
    assert_difference("Partner.count", -1) do
      delete partner_url(@partner)
    end

    assert_redirected_to partners_url
  end
end
