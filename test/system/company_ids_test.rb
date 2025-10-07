require "application_system_test_case"

class CompanyIdsTest < ApplicationSystemTestCase
  setup do
    @company_id = company_ids(:one)
  end

  test "visiting the index" do
    visit company_ids_url
    assert_selector "h1", text: "Companies"
  end

  test "should create company" do
    visit company_ids_url
    click_on "New company"

    fill_in "Account", with: @company_id.account_id
    fill_in "Company", with: @company_id.company_id
    click_on "Create Company"

    assert_text "Company was successfully created"
    click_on "Back"
  end

  test "should update Company" do
    visit company_id_url(@company_id)
    click_on "Edit this company", match: :first

    fill_in "Account", with: @company_id.account_id
    fill_in "Company", with: @company_id.company_id
    click_on "Update Company"

    assert_text "Company was successfully updated"
    click_on "Back"
  end

  test "should destroy Company" do
    visit company_id_url(@company_id)
    click_on "Destroy this company", match: :first

    assert_text "Company was successfully destroyed"
  end
end
