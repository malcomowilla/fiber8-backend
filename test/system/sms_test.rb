require "application_system_test_case"

class SmsTest < ApplicationSystemTestCase
  setup do
    @sm = sms(:one)
  end

  test "visiting the index" do
    visit sms_url
    assert_selector "h1", text: "Sms"
  end

  test "should create sm" do
    visit sms_url
    click_on "New sm"

    fill_in "Account", with: @sm.account_id
    fill_in "Admin user", with: @sm.admin_user
    fill_in "Date", with: @sm.date
    fill_in "Message", with: @sm.message
    fill_in "Status", with: @sm.status
    fill_in "System user", with: @sm.system_user
    fill_in "User", with: @sm.user
    click_on "Create Sm"

    assert_text "Sm was successfully created"
    click_on "Back"
  end

  test "should update Sm" do
    visit sm_url(@sm)
    click_on "Edit this sm", match: :first

    fill_in "Account", with: @sm.account_id
    fill_in "Admin user", with: @sm.admin_user
    fill_in "Date", with: @sm.date
    fill_in "Message", with: @sm.message
    fill_in "Status", with: @sm.status
    fill_in "System user", with: @sm.system_user
    fill_in "User", with: @sm.user
    click_on "Update Sm"

    assert_text "Sm was successfully updated"
    click_on "Back"
  end

  test "should destroy Sm" do
    visit sm_url(@sm)
    click_on "Destroy this sm", match: :first

    assert_text "Sm was successfully destroyed"
  end
end
