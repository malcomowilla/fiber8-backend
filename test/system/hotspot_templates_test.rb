require "application_system_test_case"

class HotspotTemplatesTest < ApplicationSystemTestCase
  setup do
    @hotspot_template = hotspot_templates(:one)
  end

  test "visiting the index" do
    visit hotspot_templates_url
    assert_selector "h1", text: "Hotspot templates"
  end

  test "should create hotspot template" do
    visit hotspot_templates_url
    click_on "New hotspot template"

    fill_in "Account", with: @hotspot_template.account_id
    fill_in "Name", with: @hotspot_template.name
    fill_in "Preview image", with: @hotspot_template.preview_image
    click_on "Create Hotspot template"

    assert_text "Hotspot template was successfully created"
    click_on "Back"
  end

  test "should update Hotspot template" do
    visit hotspot_template_url(@hotspot_template)
    click_on "Edit this hotspot template", match: :first

    fill_in "Account", with: @hotspot_template.account_id
    fill_in "Name", with: @hotspot_template.name
    fill_in "Preview image", with: @hotspot_template.preview_image
    click_on "Update Hotspot template"

    assert_text "Hotspot template was successfully updated"
    click_on "Back"
  end

  test "should destroy Hotspot template" do
    visit hotspot_template_url(@hotspot_template)
    click_on "Destroy this hotspot template", match: :first

    assert_text "Hotspot template was successfully destroyed"
  end
end
