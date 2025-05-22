require "test_helper"

class CompanyLeadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company_lead = company_leads(:one)
  end

  test "should get index" do
    get company_leads_url
    assert_response :success
  end

  test "should get new" do
    get new_company_lead_url
    assert_response :success
  end

  test "should create company_lead" do
    assert_difference("CompanyLead.count") do
      post company_leads_url, params: { company_lead: { account_id: @company_lead.account_id, company_name: @company_lead.company_name, email: @company_lead.email, message: @company_lead.message, name: @company_lead.name } }
    end

    assert_redirected_to company_lead_url(CompanyLead.last)
  end

  test "should show company_lead" do
    get company_lead_url(@company_lead)
    assert_response :success
  end

  test "should get edit" do
    get edit_company_lead_url(@company_lead)
    assert_response :success
  end

  test "should update company_lead" do
    patch company_lead_url(@company_lead), params: { company_lead: { account_id: @company_lead.account_id, company_name: @company_lead.company_name, email: @company_lead.email, message: @company_lead.message, name: @company_lead.name } }
    assert_redirected_to company_lead_url(@company_lead)
  end

  test "should destroy company_lead" do
    assert_difference("CompanyLead.count", -1) do
      delete company_lead_url(@company_lead)
    end

    assert_redirected_to company_leads_url
  end
end
