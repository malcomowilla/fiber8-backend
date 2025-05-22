require "application_system_test_case"

class ClientLeadsTest < ApplicationSystemTestCase
  setup do
    @client_lead = client_leads(:one)
  end

  test "visiting the index" do
    visit client_leads_url
    assert_selector "h1", text: "Client leads"
  end

  test "should create client lead" do
    visit client_leads_url
    click_on "New client lead"

    fill_in "Company name", with: @client_lead.company_name
    fill_in "Email", with: @client_lead.email
    fill_in "Name", with: @client_lead.name
    fill_in "Phone number", with: @client_lead.phone_number
    click_on "Create Client lead"

    assert_text "Client lead was successfully created"
    click_on "Back"
  end

  test "should update Client lead" do
    visit client_lead_url(@client_lead)
    click_on "Edit this client lead", match: :first

    fill_in "Company name", with: @client_lead.company_name
    fill_in "Email", with: @client_lead.email
    fill_in "Name", with: @client_lead.name
    fill_in "Phone number", with: @client_lead.phone_number
    click_on "Update Client lead"

    assert_text "Client lead was successfully updated"
    click_on "Back"
  end

  test "should destroy Client lead" do
    visit client_lead_url(@client_lead)
    click_on "Destroy this client lead", match: :first

    assert_text "Client lead was successfully destroyed"
  end
end
