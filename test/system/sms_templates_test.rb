require "application_system_test_case"

class SmsTemplatesTest < ApplicationSystemTestCase
  setup do
    @sms_template = sms_templates(:one)
  end

  test "visiting the index" do
    visit sms_templates_url
    assert_selector "h1", text: "Sms templates"
  end

  test "should create sms template" do
    visit sms_templates_url
    click_on "New sms template"

    fill_in "Account", with: @sms_template.account_id
    fill_in "Send voucher template", with: @sms_template.send_voucher_template
    fill_in "Voucher template", with: @sms_template.voucher_template
    click_on "Create Sms template"

    assert_text "Sms template was successfully created"
    click_on "Back"
  end

  test "should update Sms template" do
    visit sms_template_url(@sms_template)
    click_on "Edit this sms template", match: :first

    fill_in "Account", with: @sms_template.account_id
    fill_in "Send voucher template", with: @sms_template.send_voucher_template
    fill_in "Voucher template", with: @sms_template.voucher_template
    click_on "Update Sms template"

    assert_text "Sms template was successfully updated"
    click_on "Back"
  end

  test "should destroy Sms template" do
    visit sms_template_url(@sms_template)
    click_on "Destroy this sms template", match: :first

    assert_text "Sms template was successfully destroyed"
  end
end
