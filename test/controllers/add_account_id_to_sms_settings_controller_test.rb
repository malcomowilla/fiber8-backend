require "test_helper"

class AddAccountIdToSmsSettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get account_id:integer" do
    get add_account_id_to_sms_settings_account_id:integer_url
    assert_response :success
  end
end
