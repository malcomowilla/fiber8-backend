require "application_system_test_case"

class ActivtyLogsTest < ApplicationSystemTestCase
  setup do
    @activty_log = activty_logs(:one)
  end

  test "visiting the index" do
    visit activty_logs_url
    assert_selector "h1", text: "Activty logs"
  end

  test "should create activty log" do
    visit activty_logs_url
    click_on "New activty log"

    fill_in "Account", with: @activty_log.account_id
    fill_in "Action", with: @activty_log.action
    fill_in "Date", with: @activty_log.date
    fill_in "Description", with: @activty_log.description
    fill_in "Subject", with: @activty_log.subject
    fill_in "User", with: @activty_log.user
    click_on "Create Activty log"

    assert_text "Activty log was successfully created"
    click_on "Back"
  end

  test "should update Activty log" do
    visit activty_log_url(@activty_log)
    click_on "Edit this activty log", match: :first

    fill_in "Account", with: @activty_log.account_id
    fill_in "Action", with: @activty_log.action
    fill_in "Date", with: @activty_log.date.to_s
    fill_in "Description", with: @activty_log.description
    fill_in "Subject", with: @activty_log.subject
    fill_in "User", with: @activty_log.user
    click_on "Update Activty log"

    assert_text "Activty log was successfully updated"
    click_on "Back"
  end

  test "should destroy Activty log" do
    visit activty_log_url(@activty_log)
    click_on "Destroy this activty log", match: :first

    assert_text "Activty log was successfully destroyed"
  end
end
