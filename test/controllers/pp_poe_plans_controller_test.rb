require "test_helper"

class PpPoePlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pp_poe_plan = pp_poe_plans(:one)
  end

  test "should get index" do
    get pp_poe_plans_url
    assert_response :success
  end

  test "should get new" do
    get new_pp_poe_plan_url
    assert_response :success
  end

  test "should create pp_poe_plan" do
    assert_difference("PpPoePlan.count") do
      post pp_poe_plans_url, params: { pp_poe_plan: { maximum_pppoe_subscribers: @pp_poe_plan.maximum_pppoe_subscribers } }
    end

    assert_redirected_to pp_poe_plan_url(PpPoePlan.last)
  end

  test "should show pp_poe_plan" do
    get pp_poe_plan_url(@pp_poe_plan)
    assert_response :success
  end

  test "should get edit" do
    get edit_pp_poe_plan_url(@pp_poe_plan)
    assert_response :success
  end

  test "should update pp_poe_plan" do
    patch pp_poe_plan_url(@pp_poe_plan), params: { pp_poe_plan: { maximum_pppoe_subscribers: @pp_poe_plan.maximum_pppoe_subscribers } }
    assert_redirected_to pp_poe_plan_url(@pp_poe_plan)
  end

  test "should destroy pp_poe_plan" do
    assert_difference("PpPoePlan.count", -1) do
      delete pp_poe_plan_url(@pp_poe_plan)
    end

    assert_redirected_to pp_poe_plans_url
  end
end
