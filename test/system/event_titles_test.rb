require "application_system_test_case"

class EventTitlesTest < ApplicationSystemTestCase
  setup do
    @event_title = event_titles(:one)
  end

  test "visiting the index" do
    visit event_titles_url
    assert_selector "h1", text: "Event titles"
  end

  test "should create event title" do
    visit event_titles_url
    click_on "New event title"

    fill_in "Account", with: @event_title.account_id
    fill_in "End", with: @event_title.end
    fill_in "End date time", with: @event_title.end_date_time
    fill_in "Start", with: @event_title.start
    fill_in "Start date time", with: @event_title.start_date_time
    fill_in "Title", with: @event_title.title
    click_on "Create Event title"

    assert_text "Event title was successfully created"
    click_on "Back"
  end

  test "should update Event title" do
    visit event_title_url(@event_title)
    click_on "Edit this event title", match: :first

    fill_in "Account", with: @event_title.account_id
    fill_in "End", with: @event_title.end.to_s
    fill_in "End date time", with: @event_title.end_date_time.to_s
    fill_in "Start", with: @event_title.start.to_s
    fill_in "Start date time", with: @event_title.start_date_time.to_s
    fill_in "Title", with: @event_title.title
    click_on "Update Event title"

    assert_text "Event title was successfully updated"
    click_on "Back"
  end

  test "should destroy Event title" do
    visit event_title_url(@event_title)
    click_on "Destroy this event title", match: :first

    assert_text "Event title was successfully destroyed"
  end
end
