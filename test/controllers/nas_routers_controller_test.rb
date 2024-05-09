require "test_helper"

class NasRoutersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @nas_router = nas_routers(:one)
  end

  test "should get index" do
    get nas_routers_url
    assert_response :success
  end

  test "should get new" do
    get new_nas_router_url
    assert_response :success
  end

  test "should create nas_router" do
    assert_difference("NasRouter.count") do
      post nas_routers_url, params: { nas_router: { ip_address: @nas_router.ip_address, name: @nas_router.name, password: @nas_router.password, username: @nas_router.username } }
    end

    assert_redirected_to nas_router_url(NasRouter.last)
  end

  test "should show nas_router" do
    get nas_router_url(@nas_router)
    assert_response :success
  end

  test "should get edit" do
    get edit_nas_router_url(@nas_router)
    assert_response :success
  end

  test "should update nas_router" do
    patch nas_router_url(@nas_router), params: { nas_router: { ip_address: @nas_router.ip_address, name: @nas_router.name, password: @nas_router.password, username: @nas_router.username } }
    assert_redirected_to nas_router_url(@nas_router)
  end

  test "should destroy nas_router" do
    assert_difference("NasRouter.count", -1) do
      delete nas_router_url(@nas_router)
    end

    assert_redirected_to nas_routers_url
  end
end
