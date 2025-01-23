require "application_system_test_case"

class SystemAdminSmsTest < ApplicationSystemTestCase
  setup do
    @system_admin_sm = system_admin_sms(:one)
  end

  test "visiting the index" do
    visit system_admin_sms_url
    assert_selector "h1", text: "System admin sms"
  end

  test "should create system admin sm" do
    visit system_admin_sms_url
    click_on "New system admin sm"

    fill_in "Date", with: @system_admin_sm.date
    fill_in "Message", with: @system_admin_sm.message
    fill_in "Status", with: @system_admin_sm.status
    fill_in "System user", with: @system_admin_sm.system_user
    fill_in "User", with: @system_admin_sm.user
    click_on "Create System admin sm"

    assert_text "System admin sm was successfully created"
    click_on "Back"
  end

  test "should update System admin sm" do
    visit system_admin_sm_url(@system_admin_sm)
    click_on "Edit this system admin sm", match: :first

    fill_in "Date", with: @system_admin_sm.date
    fill_in "Message", with: @system_admin_sm.message
    fill_in "Status", with: @system_admin_sm.status
    fill_in "System user", with: @system_admin_sm.system_user
    fill_in "User", with: @system_admin_sm.user
    click_on "Update System admin sm"

    assert_text "System admin sm was successfully updated"
    click_on "Back"
  end

  test "should destroy System admin sm" do
    visit system_admin_sm_url(@system_admin_sm)
    click_on "Destroy this system admin sm", match: :first

    assert_text "System admin sm was successfully destroyed"
  end
end
