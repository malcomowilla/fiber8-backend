class SmsTemplateSerializer < ActiveModel::Serializer
  attributes :id, :send_voucher_template, :voucher_template, :account_id
end
