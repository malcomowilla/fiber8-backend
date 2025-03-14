require "test_helper"

class HotspotPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_plan = hotspot_plans(:one)
  end

  test "should get index" do
    get hotspot_plans_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_plan_url
    assert_response :success
  end

  test "should create hotspot_plan" do
    assert_difference("HotspotPlan.count") do
      post hotspot_plans_url, params: { hotspot_plan: { hotspot_subscribers: @hotspot_plan.hotspot_subscribers, name: @hotspot_plan.name } }
    end

    assert_redirected_to hotspot_plan_url(HotspotPlan.last)
  end

  test "should show hotspot_plan" do
    get hotspot_plan_url(@hotspot_plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_plan_url(@hotspot_plan)
    assert_response :success
  end

  test "should update hotspot_plan" do
    patch hotspot_plan_url(@hotspot_plan), params: { hotspot_plan: { hotspot_subscribers: @hotspot_plan.hotspot_subscribers, name: @hotspot_plan.name } }
    assert_redirected_to hotspot_plan_url(@hotspot_plan)
  end

  test "should destroy hotspot_plan" do
    assert_difference("HotspotPlan.count", -1) do
      delete hotspot_plan_url(@hotspot_plan)
    end

    assert_redirected_to hotspot_plans_url
  end
end
