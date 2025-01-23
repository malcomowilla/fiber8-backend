require "application_system_test_case"

class CompanySettingsTest < ApplicationSystemTestCase
  setup do
    @company_setting = company_settings(:one)
  end

  test "visiting the index" do
    visit company_settings_url
    assert_selector "h1", text: "Company settings"
  end

  test "should create company setting" do
    visit company_settings_url
    click_on "New company setting"

    fill_in "Agent email", with: @company_setting.agent_email
    fill_in "Company name", with: @company_setting.company_name
    fill_in "Contact info", with: @company_setting.contact_info
    fill_in "Customer support email", with: @company_setting.customer_support_email
    fill_in "Customer support phone number", with: @company_setting.customer_support_phone_number
    fill_in "Email info", with: @company_setting.email_info
    click_on "Create Company setting"

    assert_text "Company setting was successfully created"
    click_on "Back"
  end

  test "should update Company setting" do
    visit company_setting_url(@company_setting)
    click_on "Edit this company setting", match: :first

    fill_in "Agent email", with: @company_setting.agent_email
    fill_in "Company name", with: @company_setting.company_name
    fill_in "Contact info", with: @company_setting.contact_info
    fill_in "Customer support email", with: @company_setting.customer_support_email
    fill_in "Customer support phone number", with: @company_setting.customer_support_phone_number
    fill_in "Email info", with: @company_setting.email_info
    click_on "Update Company setting"

    assert_text "Company setting was successfully updated"
    click_on "Back"
  end

  test "should destroy Company setting" do
    visit company_setting_url(@company_setting)
    click_on "Destroy this company setting", match: :first

    assert_text "Company setting was successfully destroyed"
  end
end
