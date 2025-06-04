require "application_system_test_case"

class CalendarEventsTest < ApplicationSystemTestCase
  setup do
    @calendar_event = calendar_events(:one)
  end

  test "visiting the index" do
    visit calendar_events_url
    assert_selector "h1", text: "Calendar events"
  end

  test "should create calendar event" do
    visit calendar_events_url
    click_on "New calendar event"

    fill_in "Account", with: @calendar_event.account_id
    fill_in "End", with: @calendar_event.end
    fill_in "End date time", with: @calendar_event.end_date_time
    fill_in "Event title", with: @calendar_event.event_title
    fill_in "Start", with: @calendar_event.start
    fill_in "Start date time", with: @calendar_event.start_date_time
    fill_in "Title", with: @calendar_event.title
    click_on "Create Calendar event"

    assert_text "Calendar event was successfully created"
    click_on "Back"
  end

  test "should update Calendar event" do
    visit calendar_event_url(@calendar_event)
    click_on "Edit this calendar event", match: :first

    fill_in "Account", with: @calendar_event.account_id
    fill_in "End", with: @calendar_event.end.to_s
    fill_in "End date time", with: @calendar_event.end_date_time.to_s
    fill_in "Event title", with: @calendar_event.event_title
    fill_in "Start", with: @calendar_event.start.to_s
    fill_in "Start date time", with: @calendar_event.start_date_time.to_s
    fill_in "Title", with: @calendar_event.title
    click_on "Update Calendar event"

    assert_text "Calendar event was successfully updated"
    click_on "Back"
  end

  test "should destroy Calendar event" do
    visit calendar_event_url(@calendar_event)
    click_on "Destroy this calendar event", match: :first

    assert_text "Calendar event was successfully destroyed"
  end
end
