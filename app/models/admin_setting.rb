class AdminSetting < ApplicationRecord
  belongs_to :user
  acts_as_tenant(:account)

  # before_validation :set_user, on: :create

  private

  # def set_user
  #   self.user ||= Thread.current[:current_user] # Set user automatically
  # end


end
