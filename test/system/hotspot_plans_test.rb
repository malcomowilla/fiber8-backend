require "application_system_test_case"

class HotspotPlansTest < ApplicationSystemTestCase
  setup do
    @hotspot_plan = hotspot_plans(:one)
  end

  test "visiting the index" do
    visit hotspot_plans_url
    assert_selector "h1", text: "Hotspot plans"
  end

  test "should create hotspot plan" do
    visit hotspot_plans_url
    click_on "New hotspot plan"

    fill_in "Hotspot subscribers", with: @hotspot_plan.hotspot_subscribers
    fill_in "Name", with: @hotspot_plan.name
    click_on "Create Hotspot plan"

    assert_text "Hotspot plan was successfully created"
    click_on "Back"
  end

  test "should update Hotspot plan" do
    visit hotspot_plan_url(@hotspot_plan)
    click_on "Edit this hotspot plan", match: :first

    fill_in "Hotspot subscribers", with: @hotspot_plan.hotspot_subscribers
    fill_in "Name", with: @hotspot_plan.name
    click_on "Update Hotspot plan"

    assert_text "Hotspot plan was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot plan" do
    visit hotspot_plan_url(@hotspot_plan)
    click_on "Destroy this hotspot plan", match: :first

    assert_text "Hotspot plan was successfully destroyed"
  end
end
