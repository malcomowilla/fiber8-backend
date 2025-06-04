require "test_helper"

class EventTitlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @event_title = event_titles(:one)
  end

  test "should get index" do
    get event_titles_url
    assert_response :success
  end

  test "should get new" do
    get new_event_title_url
    assert_response :success
  end

  test "should create event_title" do
    assert_difference("EventTitle.count") do
      post event_titles_url, params: { event_title: { account_id: @event_title.account_id, end: @event_title.end, end_date_time: @event_title.end_date_time, start: @event_title.start, start_date_time: @event_title.start_date_time, title: @event_title.title } }
    end

    assert_redirected_to event_title_url(EventTitle.last)
  end

  test "should show event_title" do
    get event_title_url(@event_title)
    assert_response :success
  end

  test "should get edit" do
    get edit_event_title_url(@event_title)
    assert_response :success
  end

  test "should update event_title" do
    patch event_title_url(@event_title), params: { event_title: { account_id: @event_title.account_id, end: @event_title.end, end_date_time: @event_title.end_date_time, start: @event_title.start, start_date_time: @event_title.start_date_time, title: @event_title.title } }
    assert_redirected_to event_title_url(@event_title)
  end

  test "should destroy event_title" do
    assert_difference("EventTitle.count", -1) do
      delete event_title_url(@event_title)
    end

    assert_redirected_to event_titles_url
  end
end
