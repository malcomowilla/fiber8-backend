require "test_helper"

class CompanySettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @company_setting = company_settings(:one)
  end

  test "should get index" do
    get company_settings_url
    assert_response :success
  end

  test "should get new" do
    get new_company_setting_url
    assert_response :success
  end

  test "should create company_setting" do
    assert_difference("CompanySetting.count") do
      post company_settings_url, params: { company_setting: { agent_email: @company_setting.agent_email, company_name: @company_setting.company_name, contact_info: @company_setting.contact_info, customer_support_email: @company_setting.customer_support_email, customer_support_phone_number: @company_setting.customer_support_phone_number, email_info: @company_setting.email_info } }
    end

    assert_redirected_to company_setting_url(CompanySetting.last)
  end

  test "should show company_setting" do
    get company_setting_url(@company_setting)
    assert_response :success
  end

  test "should get edit" do
    get edit_company_setting_url(@company_setting)
    assert_response :success
  end

  test "should update company_setting" do
    patch company_setting_url(@company_setting), params: { company_setting: { agent_email: @company_setting.agent_email, company_name: @company_setting.company_name, contact_info: @company_setting.contact_info, customer_support_email: @company_setting.customer_support_email, customer_support_phone_number: @company_setting.customer_support_phone_number, email_info: @company_setting.email_info } }
    assert_redirected_to company_setting_url(@company_setting)
  end

  test "should destroy company_setting" do
    assert_difference("CompanySetting.count", -1) do
      delete company_setting_url(@company_setting)
    end

    assert_redirected_to company_settings_url
  end
end
