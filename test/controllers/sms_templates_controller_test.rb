require "test_helper"

class SmsTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @sms_template = sms_templates(:one)
  end

  test "should get index" do
    get sms_templates_url
    assert_response :success
  end

  test "should get new" do
    get new_sms_template_url
    assert_response :success
  end

  test "should create sms_template" do
    assert_difference("SmsTemplate.count") do
      post sms_templates_url, params: { sms_template: { account_id: @sms_template.account_id, send_voucher_template: @sms_template.send_voucher_template, voucher_template: @sms_template.voucher_template } }
    end

    assert_redirected_to sms_template_url(SmsTemplate.last)
  end

  test "should show sms_template" do
    get sms_template_url(@sms_template)
    assert_response :success
  end

  test "should get edit" do
    get edit_sms_template_url(@sms_template)
    assert_response :success
  end

  test "should update sms_template" do
    patch sms_template_url(@sms_template), params: { sms_template: { account_id: @sms_template.account_id, send_voucher_template: @sms_template.send_voucher_template, voucher_template: @sms_template.voucher_template } }
    assert_redirected_to sms_template_url(@sms_template)
  end

  test "should destroy sms_template" do
    assert_difference("SmsTemplate.count", -1) do
      delete sms_template_url(@sms_template)
    end

    assert_redirected_to sms_templates_url
  end
end
