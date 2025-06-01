require "application_system_test_case"

class ChangeLogsTest < ApplicationSystemTestCase
  setup do
    @change_log = change_logs(:one)
  end

  test "visiting the index" do
    visit change_logs_url
    assert_selector "h1", text: "Change logs"
  end

  test "should create change log" do
    visit change_logs_url
    click_on "New change log"

    fill_in "Change title", with: @change_log.change_title
    fill_in "System changes", with: @change_log.system_changes
    fill_in "Version", with: @change_log.version
    click_on "Create Change log"

    assert_text "Change log was successfully created"
    click_on "Back"
  end

  test "should update Change log" do
    visit change_log_url(@change_log)
    click_on "Edit this change log", match: :first

    fill_in "Change title", with: @change_log.change_title
    fill_in "System changes", with: @change_log.system_changes
    fill_in "Version", with: @change_log.version
    click_on "Update Change log"

    assert_text "Change log was successfully updated"
    click_on "Back"
  end

  test "should destroy Change log" do
    visit change_log_url(@change_log)
    click_on "Destroy this change log", match: :first

    assert_text "Change log was successfully destroyed"
  end
end
