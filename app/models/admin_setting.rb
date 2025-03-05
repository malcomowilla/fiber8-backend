class AdminSetting < ApplicationRecord
  belongs_to :user
  acts_as_tenant(:account)
  # scope :for_user, ->(user_id) { where(user_id: user_id) }
  # before_validation :set_user, on: :create

  private

  # def set_user
  #   self.user ||= Thread.current[:current_user] # Set user automatically
  # end


end
