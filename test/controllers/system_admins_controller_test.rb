require "test_helper"

class SystemAdminsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_admin = system_admins(:one)
  end

  test "should get index" do
    get system_admins_url
    assert_response :success
  end

  test "should get new" do
    get new_system_admin_url
    assert_response :success
  end

  test "should create system_admin" do
    assert_difference("SystemAdmin.count") do
      post system_admins_url, params: { system_admin: { email: @system_admin.email, email_verified: @system_admin.email_verified, fcm_token: @system_admin.fcm_token, login_with_passkey: @system_admin.login_with_passkey, password_digest: @system_admin.password_digest, role: @system_admin.role, user_name: @system_admin.user_name, verification_token: @system_admin.verification_token, webauthn_authenticator_attachment: @system_admin.webauthn_authenticator_attachment, webauthn_id: @system_admin.webauthn_id } }
    end

    assert_redirected_to system_admin_url(SystemAdmin.last)
  end

  test "should show system_admin" do
    get system_admin_url(@system_admin)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_admin_url(@system_admin)
    assert_response :success
  end

  test "should update system_admin" do
    patch system_admin_url(@system_admin), params: { system_admin: { email: @system_admin.email, email_verified: @system_admin.email_verified, fcm_token: @system_admin.fcm_token, login_with_passkey: @system_admin.login_with_passkey, password_digest: @system_admin.password_digest, role: @system_admin.role, user_name: @system_admin.user_name, verification_token: @system_admin.verification_token, webauthn_authenticator_attachment: @system_admin.webauthn_authenticator_attachment, webauthn_id: @system_admin.webauthn_id } }
    assert_redirected_to system_admin_url(@system_admin)
  end

  test "should destroy system_admin" do
    assert_difference("SystemAdmin.count", -1) do
      delete system_admin_url(@system_admin)
    end

    assert_redirected_to system_admins_url
  end
end
