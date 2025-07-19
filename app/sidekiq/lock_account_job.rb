class LockAccountJob
  include Sidekiq::Job
  queue_as :default

  def perform
    RadAcct.where(framedprotocol: 'PPP').where.not(callingstationid: [nil, '']).find_each do |radacct|
      subscription = Subscription.find_by(ppoe_username: radacct.username)
      next unless subscription

      # Only proceed if RadCheck is not already created
      existing_check = RadCheck.find_by(
        username: subscription.ppoe_username,
        radiusattribute: 'Calling-Station-Id'
      )
      next if existing_check.present?

      # Save the MAC if not already stored
      if subscription.mac_address.blank?
        subscription.update(mac_address: radacct.callingstationid)
        Rails.logger.info "MAC locked on subscription #{subscription.id}: #{subscription.mac_adress}"
      end

      # Create RadCheck to enforce sticky MAC
      RadCheck.create!(
        username: subscription.ppoe_username,
        radiusattribute: 'Calling-Station-Id',
        op: '==',
        value: radacct.callingstationid
      )
    end
  end
end




