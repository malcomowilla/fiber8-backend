# app/models/ad_event.rb
class AdEvent < ApplicationRecord
  belongs_to :ad_setting, optional: true
  belongs_to :account
end