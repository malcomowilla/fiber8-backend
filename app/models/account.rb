class Account < ApplicationRecord
    has_many :users, dependent: :destroy
    has_many :packages, dependent: :destroy
    has_many :nas_routers, dependent: :destroy
    has_many :zones, dependent: :destroy
    has_many :subscribers, dependent: :destroy
    has_one :sms_setting, dependent: :destroy
    has_many :subscriptions, dependent: :destroy    
    has_many :prefix_and_digits, dependent: :destroy
    has_one :company_setting, dependent: :destroy
    has_one :email_setting, dependent: :destroy
    has_one :router_setting, dependent: :destroy
    has_one :subscriber_setting, dependent: :destroy
    has_one :ticket_setting, dependent: :destroy
    has_one :admin_setting, dependent: :destroy
    has_one :sms_template, dependent: :destroy
    # validates :subdomain, presence: true
    
end
