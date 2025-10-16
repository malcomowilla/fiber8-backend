require "application_system_test_case"

class GoogleMapsTest < ApplicationSystemTestCase
  setup do
    @google_map = google_maps(:one)
  end

  test "visiting the index" do
    visit google_maps_url
    assert_selector "h1", text: "Google maps"
  end

  test "should create google map" do
    visit google_maps_url
    click_on "New google map"

    fill_in "Account", with: @google_map.account_id
    fill_in "Api key", with: @google_map.api_key
    click_on "Create Google map"

    assert_text "Google map was successfully created"
    click_on "Back"
  end

  test "should update Google map" do
    visit google_map_url(@google_map)
    click_on "Edit this google map", match: :first

    fill_in "Account", with: @google_map.account_id
    fill_in "Api key", with: @google_map.api_key
    click_on "Update Google map"

    assert_text "Google map was successfully updated"
    click_on "Back"
  end

  test "should destroy Google map" do
    visit google_map_url(@google_map)
    click_on "Destroy this google map", match: :first

    assert_text "Google map was successfully destroyed"
  end
end
