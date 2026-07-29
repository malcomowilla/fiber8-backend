class RemoteWinboxExpiryJob < ApplicationJob
queue_as :default
  # def perform(router_id, port)
  #   router = NasRouter.find_by(id: router_id)
  #   return unless router
  #   system("iptables -t nat -D PREROUTING -p tcp --dport #{port} -j DNAT --to-destination #{router.ip_address}:8291")
  #   system("iptables -t nat -D POSTROUTING -p tcp -d #{router.ip_address} --dport 8291 -j MASQUERADE")
  # end




  def perform(router_id, port)
    router = NasRouter.find_by(id: router_id)
    return unless router
    return unless router.winbox_relay_port == port # a newer session already replaced this port

    system('iptables', '-t', 'nat', '-D', 'PREROUTING', '-p', 'tcp',
           '--dport', port.to_s, '-j', 'DNAT',
           '--to-destination', "#{router.ip_address}:8291")

    system('iptables', '-t', 'nat', '-D', 'POSTROUTING', '-p', 'tcp',
           '-d', router.ip_address, '--dport', '8291', '-j', 'MASQUERADE')

    router.update!(winbox_relay_port: nil, winbox_relay_expires_at: nil)
  end
end