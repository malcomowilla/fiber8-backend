require "application_system_test_case"

class PpPoePlansTest < ApplicationSystemTestCase
  setup do
    @pp_poe_plan = pp_poe_plans(:one)
  end

  test "visiting the index" do
    visit pp_poe_plans_url
    assert_selector "h1", text: "Pp poe plans"
  end

  test "should create pp poe plan" do
    visit pp_poe_plans_url
    click_on "New pp poe plan"

    fill_in "Maximum pppoe subscribers", with: @pp_poe_plan.maximum_pppoe_subscribers
    click_on "Create Pp poe plan"

    assert_text "Pp poe plan was successfully created"
    click_on "Back"
  end

  test "should update Pp poe plan" do
    visit pp_poe_plan_url(@pp_poe_plan)
    click_on "Edit this pp poe plan", match: :first

    fill_in "Maximum pppoe subscribers", with: @pp_poe_plan.maximum_pppoe_subscribers
    click_on "Update Pp poe plan"

    assert_text "Pp poe plan was successfully updated"
    click_on "Back"
  end

  test "should destroy Pp poe plan" do
    visit pp_poe_plan_url(@pp_poe_plan)
    click_on "Destroy this pp poe plan", match: :first

    assert_text "Pp poe plan was successfully destroyed"
  end
end
