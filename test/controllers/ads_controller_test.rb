require "test_helper"

class AdsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @ad = ads(:one)
  end

  test "should get index" do
    get ads_url
    assert_response :success
  end

  test "should get new" do
    get new_ad_url
    assert_response :success
  end

  test "should create ad" do
    assert_difference("Ad.count") do
      post ads_url, params: { ad: { account_id: @ad.account_id, background_color: @ad.background_color, business_name: @ad.business_name, business_type: @ad.business_type, cat_text: @ad.cat_text, description: @ad.description, discount: @ad.discount, image: @ad.image, imagePreview: @ad.imagePreview, is_active: @ad.is_active, offer_text: @ad.offer_text, target_url: @ad.target_url, text_color: @ad.text_color, title: @ad.title } }
    end

    assert_redirected_to ad_url(Ad.last)
  end

  test "should show ad" do
    get ad_url(@ad)
    assert_response :success
  end

  test "should get edit" do
    get edit_ad_url(@ad)
    assert_response :success
  end

  test "should update ad" do
    patch ad_url(@ad), params: { ad: { account_id: @ad.account_id, background_color: @ad.background_color, business_name: @ad.business_name, business_type: @ad.business_type, cat_text: @ad.cat_text, description: @ad.description, discount: @ad.discount, image: @ad.image, imagePreview: @ad.imagePreview, is_active: @ad.is_active, offer_text: @ad.offer_text, target_url: @ad.target_url, text_color: @ad.text_color, title: @ad.title } }
    assert_redirected_to ad_url(@ad)
  end

  test "should destroy ad" do
    assert_difference("Ad.count", -1) do
      delete ad_url(@ad)
    end

    assert_redirected_to ads_url
  end
end
