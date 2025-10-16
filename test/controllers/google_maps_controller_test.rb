require "test_helper"

class GoogleMapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @google_map = google_maps(:one)
  end

  test "should get index" do
    get google_maps_url
    assert_response :success
  end

  test "should get new" do
    get new_google_map_url
    assert_response :success
  end

  test "should create google_map" do
    assert_difference("GoogleMap.count") do
      post google_maps_url, params: { google_map: { account_id: @google_map.account_id, api_key: @google_map.api_key } }
    end

    assert_redirected_to google_map_url(GoogleMap.last)
  end

  test "should show google_map" do
    get google_map_url(@google_map)
    assert_response :success
  end

  test "should get edit" do
    get edit_google_map_url(@google_map)
    assert_response :success
  end

  test "should update google_map" do
    patch google_map_url(@google_map), params: { google_map: { account_id: @google_map.account_id, api_key: @google_map.api_key } }
    assert_redirected_to google_map_url(@google_map)
  end

  test "should destroy google_map" do
    assert_difference("GoogleMap.count", -1) do
      delete google_map_url(@google_map)
    end

    assert_redirected_to google_maps_url
  end
end
