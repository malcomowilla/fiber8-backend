class AdminSettingSerializer < ActiveModel::Serializer
  attributes :id, :enable_2fa_for_admin_email,:enable_2fa_for_admin_sms,:send_password_via_sms,
  :send_password_via_email, :enable_2fa_for_admin_passkeys, :check_is_inactive,
:checkinactiveminutes, :checkinactivehrs,:checkinactivedays, :user_id, :account_id,
:enable_2fa_google_auth


end




