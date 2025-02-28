require "test_helper"

class HotspotTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @hotspot_template = hotspot_templates(:one)
  end

  test "should get index" do
    get hotspot_templates_url
    assert_response :success
  end

  test "should get new" do
    get new_hotspot_template_url
    assert_response :success
  end

  test "should create hotspot_template" do
    assert_difference("HotspotTemplate.count") do
      post hotspot_templates_url, params: { hotspot_template: { account_id: @hotspot_template.account_id, name: @hotspot_template.name, preview_image: @hotspot_template.preview_image } }
    end

    assert_redirected_to hotspot_template_url(HotspotTemplate.last)
  end

  test "should show hotspot_template" do
    get hotspot_template_url(@hotspot_template)
    assert_response :success
  end

  test "should get edit" do
    get edit_hotspot_template_url(@hotspot_template)
    assert_response :success
  end

  test "should update hotspot_template" do
    patch hotspot_template_url(@hotspot_template), params: { hotspot_template: { account_id: @hotspot_template.account_id, name: @hotspot_template.name, preview_image: @hotspot_template.preview_image } }
    assert_redirected_to hotspot_template_url(@hotspot_template)
  end

  test "should destroy hotspot_template" do
    assert_difference("HotspotTemplate.count", -1) do
      delete hotspot_template_url(@hotspot_template)
    end

    assert_redirected_to hotspot_templates_url
  end
end
