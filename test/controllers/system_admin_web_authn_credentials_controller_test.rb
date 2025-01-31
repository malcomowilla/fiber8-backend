require "test_helper"

class SystemAdminWebAuthnCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @system_admin_web_authn_credential = system_admin_web_authn_credentials(:one)
  end

  test "should get index" do
    get system_admin_web_authn_credentials_url
    assert_response :success
  end

  test "should get new" do
    get new_system_admin_web_authn_credential_url
    assert_response :success
  end

  test "should create system_admin_web_authn_credential" do
    assert_difference("SystemAdminWebAuthnCredential.count") do
      post system_admin_web_authn_credentials_url, params: { system_admin_web_authn_credential: { public_key: @system_admin_web_authn_credential.public_key, sign_count: @system_admin_web_authn_credential.sign_count, system_admin_id: @system_admin_web_authn_credential.system_admin_id, webauthn_id: @system_admin_web_authn_credential.webauthn_id } }
    end

    assert_redirected_to system_admin_web_authn_credential_url(SystemAdminWebAuthnCredential.last)
  end

  test "should show system_admin_web_authn_credential" do
    get system_admin_web_authn_credential_url(@system_admin_web_authn_credential)
    assert_response :success
  end

  test "should get edit" do
    get edit_system_admin_web_authn_credential_url(@system_admin_web_authn_credential)
    assert_response :success
  end

  test "should update system_admin_web_authn_credential" do
    patch system_admin_web_authn_credential_url(@system_admin_web_authn_credential), params: { system_admin_web_authn_credential: { public_key: @system_admin_web_authn_credential.public_key, sign_count: @system_admin_web_authn_credential.sign_count, system_admin_id: @system_admin_web_authn_credential.system_admin_id, webauthn_id: @system_admin_web_authn_credential.webauthn_id } }
    assert_redirected_to system_admin_web_authn_credential_url(@system_admin_web_authn_credential)
  end

  test "should destroy system_admin_web_authn_credential" do
    assert_difference("SystemAdminWebAuthnCredential.count", -1) do
      delete system_admin_web_authn_credential_url(@system_admin_web_authn_credential)
    end

    assert_redirected_to system_admin_web_authn_credentials_url
  end
end
