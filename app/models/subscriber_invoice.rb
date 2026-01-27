class SubscriberInvoice < ApplicationRecord

  acts_as_tenant(:account)

  belongs_to :subscriber

end

