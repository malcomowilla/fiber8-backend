require "test_helper"

class ClientLeadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @client_lead = client_leads(:one)
  end

  test "should get index" do
    get client_leads_url
    assert_response :success
  end

  test "should get new" do
    get new_client_lead_url
    assert_response :success
  end

  test "should create client_lead" do
    assert_difference("ClientLead.count") do
      post client_leads_url, params: { client_lead: { company_name: @client_lead.company_name, email: @client_lead.email, name: @client_lead.name, phone_number: @client_lead.phone_number } }
    end

    assert_redirected_to client_lead_url(ClientLead.last)
  end

  test "should show client_lead" do
    get client_lead_url(@client_lead)
    assert_response :success
  end

  test "should get edit" do
    get edit_client_lead_url(@client_lead)
    assert_response :success
  end

  test "should update client_lead" do
    patch client_lead_url(@client_lead), params: { client_lead: { company_name: @client_lead.company_name, email: @client_lead.email, name: @client_lead.name, phone_number: @client_lead.phone_number } }
    assert_redirected_to client_lead_url(@client_lead)
  end

  test "should destroy client_lead" do
    assert_difference("ClientLead.count", -1) do
      delete client_lead_url(@client_lead)
    end

    assert_redirected_to client_leads_url
  end
end
