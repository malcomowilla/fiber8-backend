class SubscriberSettingSerializer < ActiveModel::Serializer
  attributes :id, :prefix, :minimum_digits, :account_id, :use_autogenerated_number_as_ppoe_username, 
  :notify_user_account_created, :send_reminder_sms_expiring_subscriptions,:use_autogenerated_number_as_ppoe_password
end
