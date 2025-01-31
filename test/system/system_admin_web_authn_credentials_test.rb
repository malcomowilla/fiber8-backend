require "application_system_test_case"

class SystemAdminWebAuthnCredentialsTest < ApplicationSystemTestCase
  setup do
    @system_admin_web_authn_credential = system_admin_web_authn_credentials(:one)
  end

  test "visiting the index" do
    visit system_admin_web_authn_credentials_url
    assert_selector "h1", text: "System admin web authn credentials"
  end

  test "should create system admin web authn credential" do
    visit system_admin_web_authn_credentials_url
    click_on "New system admin web authn credential"

    fill_in "Public key", with: @system_admin_web_authn_credential.public_key
    fill_in "Sign count", with: @system_admin_web_authn_credential.sign_count
    fill_in "System admin", with: @system_admin_web_authn_credential.system_admin_id
    fill_in "Webauthn", with: @system_admin_web_authn_credential.webauthn_id
    click_on "Create System admin web authn credential"

    assert_text "System admin web authn credential was successfully created"
    click_on "Back"
  end

  test "should update System admin web authn credential" do
    visit system_admin_web_authn_credential_url(@system_admin_web_authn_credential)
    click_on "Edit this system admin web authn credential", match: :first

    fill_in "Public key", with: @system_admin_web_authn_credential.public_key
    fill_in "Sign count", with: @system_admin_web_authn_credential.sign_count
    fill_in "System admin", with: @system_admin_web_authn_credential.system_admin_id
    fill_in "Webauthn", with: @system_admin_web_authn_credential.webauthn_id
    click_on "Update System admin web authn credential"

    assert_text "System admin web authn credential was successfully updated"
    click_on "Back"
  end

  test "should destroy System admin web authn credential" do
    visit system_admin_web_authn_credential_url(@system_admin_web_authn_credential)
    click_on "Destroy this system admin web authn credential", match: :first

    assert_text "System admin web authn credential was successfully destroyed"
  end
end
