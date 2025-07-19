class LockAccountJob
  include Sidekiq::Job
  queue_as :default



  def perform
    RadAcct.where.not(callingstationid: [nil, '']).where(framedprotocol: 'PPP').find_each do |radacct|
      subscription = Subscription.find_by(pppoe_username: radacct.username)

      next unless subscription
      next if subscription.mac_adress.present? # Already locked

      # Save the MAC address to the subscription
      subscription.update(mac_adress: radacct.callingstationid)

      # Create the Radcheck rule to lock MAC
      Radcheck.find_or_create_by!(
        username: subscription.ppoe_username,
        attribute: 'Calling-Station-Id',
        op: '==',
        value: radacct.callingstationid
      )
    end
  end
end




