require "application_system_test_case"

class IpBindingsTest < ApplicationSystemTestCase
  setup do
    @ip_binding = ip_bindings(:one)
  end

  test "visiting the index" do
    visit ip_bindings_url
    assert_selector "h1", text: "Ip bindings"
  end

  test "should create ip binding" do
    visit ip_bindings_url
    click_on "New ip binding"

    fill_in "Account", with: @ip_binding.account_id
    fill_in "Device type", with: @ip_binding.device_type
    fill_in "Expiry", with: @ip_binding.expiry
    fill_in "Ip", with: @ip_binding.ip
    fill_in "Mac", with: @ip_binding.mac
    fill_in "Name", with: @ip_binding.name
    fill_in "Package", with: @ip_binding.package
    fill_in "Router", with: @ip_binding.router
    fill_in "Router", with: @ip_binding.router_id
    click_on "Create Ip binding"

    assert_text "Ip binding was successfully created"
    click_on "Back"
  end

  test "should update Ip binding" do
    visit ip_binding_url(@ip_binding)
    click_on "Edit this ip binding", match: :first

    fill_in "Account", with: @ip_binding.account_id
    fill_in "Device type", with: @ip_binding.device_type
    fill_in "Expiry", with: @ip_binding.expiry
    fill_in "Ip", with: @ip_binding.ip
    fill_in "Mac", with: @ip_binding.mac
    fill_in "Name", with: @ip_binding.name
    fill_in "Package", with: @ip_binding.package
    fill_in "Router", with: @ip_binding.router
    fill_in "Router", with: @ip_binding.router_id
    click_on "Update Ip binding"

    assert_text "Ip binding was successfully updated"
    click_on "Back"
  end

  test "should destroy Ip binding" do
    visit ip_binding_url(@ip_binding)
    click_on "Destroy this ip binding", match: :first

    assert_text "Ip binding was successfully destroyed"
  end
end
