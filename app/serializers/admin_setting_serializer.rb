class AdminSettingSerializer < ActiveModel::Serializer
  attributes :id, :enable_2fa_for_admin_email,:enable_2fa_for_admin_sms,:send_password_via_sms,
  :send_password_via_email, :enable_2fa_for_admin_passkeys, :check_is_inactive,
:checkinactiveminutes, :checkinactivehrs,:checkinactivedays


end
