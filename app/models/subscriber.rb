class Subscriber < ApplicationRecord
    acts_as_tenant(:account)
    auto_increment :sequence_number
        has_secure_password(validations: false)
has_many :subscriptions, dependent: :destroy
after_commit :broadcast_subscriber_stats, on: [:create, :update, :destroy]
      # before_create :set_default_status

# after_create :update_subscriber_status


  #     def set_default_status
  #   self.status ||= 'no subscription'
  # end


def broadcast_subscriber_stats
  subscriber_count = {
    subscriber_count: Subscriber.count,
  }

  SubscriberChannel.broadcast_to(account, subscriber_count)
end
  

    def update_subscriber_status
    if self.subscriptions.exists?
      self.update_column(:status, 'active')
    else
      self.update_column(:status, 'no subscription')
    end
  end
# validates :phone_number, presence: true
# validates :name, uniqueness: true
# validates :ppoe_username, uniqueness: true




# validates :ppoe_username, presence: true
# validates :phone_number, uniqueness: true


end
