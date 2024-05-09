require "application_system_test_case"

class NasRoutersTest < ApplicationSystemTestCase
  setup do
    @nas_router = nas_routers(:one)
  end

  test "visiting the index" do
    visit nas_routers_url
    assert_selector "h1", text: "Nas routers"
  end

  test "should create nas router" do
    visit nas_routers_url
    click_on "New nas router"

    fill_in "Ip address", with: @nas_router.ip_address
    fill_in "Name", with: @nas_router.name
    fill_in "Password", with: @nas_router.password
    fill_in "Username", with: @nas_router.username
    click_on "Create Nas router"

    assert_text "Nas router was successfully created"
    click_on "Back"
  end

  test "should update Nas router" do
    visit nas_router_url(@nas_router)
    click_on "Edit this nas router", match: :first

    fill_in "Ip address", with: @nas_router.ip_address
    fill_in "Name", with: @nas_router.name
    fill_in "Password", with: @nas_router.password
    fill_in "Username", with: @nas_router.username
    click_on "Update Nas router"

    assert_text "Nas router was successfully updated"
    click_on "Back"
  end

  test "should destroy Nas router" do
    visit nas_router_url(@nas_router)
    click_on "Destroy this nas router", match: :first

    assert_text "Nas router was successfully destroyed"
  end
end
