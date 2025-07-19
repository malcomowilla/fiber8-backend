class LockAccountJob
  include Sidekiq::Job
  queue_as :default

  def perform
     Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
    RadAcct.where(framedprotocol: 'PPP').where.not(callingstationid: [nil, '']).find_each do |radacct|
      subscription = Subscription.find_by(ppoe_username: radacct.username)
      next unless subscription

      # Only proceed if RadCheck is not already created
      existing_check = RadCheck.find_by(
        username: subscription.ppoe_username,
        radiusattribute: 'Calling-Station-Id',
        account_id: subscription.account_id
      )
      next if existing_check.present?

      # Save the MAC if not already stored
      if subscription.mac_address.blank?
        subscription.update(mac_address: radacct.callingstationid)
        Rails.logger.info "MAC locked on subscription #{subscription.id}: #{subscription.mac_address}"
      end

      # Create RadCheck to enforce sticky MAC
      RadCheck.create!(
        username: subscription.ppoe_username,
        account_id: subscription.account_id,
        radiusattribute: 'Calling-Station-Id',
        op: '==',
        value: radacct.callingstationid
      )
    end
  end
end
end
end



