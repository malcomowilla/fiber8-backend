class SipExtension < ApplicationRecord
   acts_as_tenant(:account)

  validates :extension,
            presence: true,
            uniqueness: true,
            format: { with: /\A[0-9]{3,10}\z/ }

  validates :name, presence: true
  validates :transport, presence: true
end



