require "application_system_test_case"

class SystemAdminsTest < ApplicationSystemTestCase
  setup do
    @system_admin = system_admins(:one)
  end

  test "visiting the index" do
    visit system_admins_url
    assert_selector "h1", text: "System admins"
  end

  test "should create system admin" do
    visit system_admins_url
    click_on "New system admin"

    fill_in "Email", with: @system_admin.email
    check "Email verified" if @system_admin.email_verified
    fill_in "Fcm token", with: @system_admin.fcm_token
    check "Login with passkey" if @system_admin.login_with_passkey
    fill_in "Password digest", with: @system_admin.password_digest
    fill_in "Role", with: @system_admin.role
    fill_in "User name", with: @system_admin.user_name
    fill_in "Verification token", with: @system_admin.verification_token
    fill_in "Webauthn authenticator attachment", with: @system_admin.webauthn_authenticator_attachment
    fill_in "Webauthn", with: @system_admin.webauthn_id
    click_on "Create System admin"

    assert_text "System admin was successfully created"
    click_on "Back"
  end

  test "should update System admin" do
    visit system_admin_url(@system_admin)
    click_on "Edit this system admin", match: :first

    fill_in "Email", with: @system_admin.email
    check "Email verified" if @system_admin.email_verified
    fill_in "Fcm token", with: @system_admin.fcm_token
    check "Login with passkey" if @system_admin.login_with_passkey
    fill_in "Password digest", with: @system_admin.password_digest
    fill_in "Role", with: @system_admin.role
    fill_in "User name", with: @system_admin.user_name
    fill_in "Verification token", with: @system_admin.verification_token
    fill_in "Webauthn authenticator attachment", with: @system_admin.webauthn_authenticator_attachment
    fill_in "Webauthn", with: @system_admin.webauthn_id
    click_on "Update System admin"

    assert_text "System admin was successfully updated"
    click_on "Back"
  end

  test "should destroy System admin" do
    visit system_admin_url(@system_admin)
    click_on "Destroy this system admin", match: :first

    assert_text "System admin was successfully destroyed"
  end
end
