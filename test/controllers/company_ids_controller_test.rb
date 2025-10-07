require "test_helper"

class CompanyIdsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company_id = company_ids(:one)
  end

  test "should get index" do
    get company_ids_url
    assert_response :success
  end

  test "should get new" do
    get new_company_id_url
    assert_response :success
  end

  test "should create company_id" do
    assert_difference("CompanyId.count") do
      post company_ids_url, params: { company_id: { account_id: @company_id.account_id, company_id: @company_id.company_id } }
    end

    assert_redirected_to company_id_url(CompanyId.last)
  end

  test "should show company_id" do
    get company_id_url(@company_id)
    assert_response :success
  end

  test "should get edit" do
    get edit_company_id_url(@company_id)
    assert_response :success
  end

  test "should update company_id" do
    patch company_id_url(@company_id), params: { company_id: { account_id: @company_id.account_id, company_id: @company_id.company_id } }
    assert_redirected_to company_id_url(@company_id)
  end

  test "should destroy company_id" do
    assert_difference("CompanyId.count", -1) do
      delete company_id_url(@company_id)
    end

    assert_redirected_to company_ids_url
  end
end
