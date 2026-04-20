require "application_system_test_case"

class PartnersTest < ApplicationSystemTestCase
  setup do
    @partner = partners(:one)
  end

  test "visiting the index" do
    visit partners_url
    assert_selector "h1", text: "Partners"
  end

  test "should create partner" do
    visit partners_url
    click_on "New partner"

    fill_in "Account", with: @partner.account_id
    fill_in "Account name", with: @partner.account_name
    fill_in "Account number", with: @partner.account_number
    fill_in "Bank name", with: @partner.bank_name
    fill_in "City", with: @partner.city
    fill_in "Commission rate", with: @partner.commission_rate
    fill_in "Commission type", with: @partner.commission_type
    fill_in "Country", with: @partner.country
    fill_in "Email", with: @partner.email
    fill_in "Fixed amount", with: @partner.fixed_amount
    fill_in "Full name", with: @partner.full_name
    fill_in "Minimum payout", with: @partner.minimum_payout
    fill_in "Mpesa name", with: @partner.mpesa_name
    fill_in "Mpesa number", with: @partner.mpesa_number
    fill_in "Notes", with: @partner.notes
    fill_in "Partner type", with: @partner.partner_type
    fill_in "Payout frequency", with: @partner.payout_frequency
    fill_in "Payout method", with: @partner.payout_method
    fill_in "Phone", with: @partner.phone
    fill_in "Status", with: @partner.status
    click_on "Create Partner"

    assert_text "Partner was successfully created"
    click_on "Back"
  end

  test "should update Partner" do
    visit partner_url(@partner)
    click_on "Edit this partner", match: :first

    fill_in "Account", with: @partner.account_id
    fill_in "Account name", with: @partner.account_name
    fill_in "Account number", with: @partner.account_number
    fill_in "Bank name", with: @partner.bank_name
    fill_in "City", with: @partner.city
    fill_in "Commission rate", with: @partner.commission_rate
    fill_in "Commission type", with: @partner.commission_type
    fill_in "Country", with: @partner.country
    fill_in "Email", with: @partner.email
    fill_in "Fixed amount", with: @partner.fixed_amount
    fill_in "Full name", with: @partner.full_name
    fill_in "Minimum payout", with: @partner.minimum_payout
    fill_in "Mpesa name", with: @partner.mpesa_name
    fill_in "Mpesa number", with: @partner.mpesa_number
    fill_in "Notes", with: @partner.notes
    fill_in "Partner type", with: @partner.partner_type
    fill_in "Payout frequency", with: @partner.payout_frequency
    fill_in "Payout method", with: @partner.payout_method
    fill_in "Phone", with: @partner.phone
    fill_in "Status", with: @partner.status
    click_on "Update Partner"

    assert_text "Partner was successfully updated"
    click_on "Back"
  end

  test "should destroy Partner" do
    visit partner_url(@partner)
    click_on "Destroy this partner", match: :first

    assert_text "Partner was successfully destroyed"
  end
end
