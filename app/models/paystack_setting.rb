# app/models/paystack_setting.rb
class PaystackSetting < ApplicationRecord
  belongs_to :account
  # validates :account_id, uniqueness: true
end