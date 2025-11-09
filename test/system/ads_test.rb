require "application_system_test_case"

class AdsTest < ApplicationSystemTestCase
  setup do
    @ad = ads(:one)
  end

  test "visiting the index" do
    visit ads_url
    assert_selector "h1", text: "Ads"
  end

  test "should create ad" do
    visit ads_url
    click_on "New ad"

    fill_in "Account", with: @ad.account_id
    fill_in "Background color", with: @ad.background_color
    fill_in "Business name", with: @ad.business_name
    fill_in "Business type", with: @ad.business_type
    fill_in "Cat text", with: @ad.cat_text
    fill_in "Description", with: @ad.description
    fill_in "Discount", with: @ad.discount
    fill_in "Image", with: @ad.image
    fill_in "Imagepreview", with: @ad.imagePreview
    check "Is active" if @ad.is_active
    fill_in "Offer text", with: @ad.offer_text
    fill_in "Target url", with: @ad.target_url
    fill_in "Text color", with: @ad.text_color
    fill_in "Title", with: @ad.title
    click_on "Create Ad"

    assert_text "Ad was successfully created"
    click_on "Back"
  end

  test "should update Ad" do
    visit ad_url(@ad)
    click_on "Edit this ad", match: :first

    fill_in "Account", with: @ad.account_id
    fill_in "Background color", with: @ad.background_color
    fill_in "Business name", with: @ad.business_name
    fill_in "Business type", with: @ad.business_type
    fill_in "Cat text", with: @ad.cat_text
    fill_in "Description", with: @ad.description
    fill_in "Discount", with: @ad.discount
    fill_in "Image", with: @ad.image
    fill_in "Imagepreview", with: @ad.imagePreview
    check "Is active" if @ad.is_active
    fill_in "Offer text", with: @ad.offer_text
    fill_in "Target url", with: @ad.target_url
    fill_in "Text color", with: @ad.text_color
    fill_in "Title", with: @ad.title
    click_on "Update Ad"

    assert_text "Ad was successfully updated"
    click_on "Back"
  end

  test "should destroy Ad" do
    visit ad_url(@ad)
    click_on "Destroy this ad", match: :first

    assert_text "Ad was successfully destroyed"
  end
end
