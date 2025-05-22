require "application_system_test_case"

class CompanyLeadsTest < ApplicationSystemTestCase
  setup do
    @company_lead = company_leads(:one)
  end

  test "visiting the index" do
    visit company_leads_url
    assert_selector "h1", text: "Company leads"
  end

  test "should create company lead" do
    visit company_leads_url
    click_on "New company lead"

    fill_in "Account", with: @company_lead.account_id
    fill_in "Company name", with: @company_lead.company_name
    fill_in "Email", with: @company_lead.email
    fill_in "Message", with: @company_lead.message
    fill_in "Name", with: @company_lead.name
    click_on "Create Company lead"

    assert_text "Company lead was successfully created"
    click_on "Back"
  end

  test "should update Company lead" do
    visit company_lead_url(@company_lead)
    click_on "Edit this company lead", match: :first

    fill_in "Account", with: @company_lead.account_id
    fill_in "Company name", with: @company_lead.company_name
    fill_in "Email", with: @company_lead.email
    fill_in "Message", with: @company_lead.message
    fill_in "Name", with: @company_lead.name
    click_on "Update Company lead"

    assert_text "Company lead was successfully updated"
    click_on "Back"
  end

  test "should destroy Company lead" do
    visit company_lead_url(@company_lead)
    click_on "Destroy this company lead", match: :first

    assert_text "Company lead was successfully destroyed"
  end
end
