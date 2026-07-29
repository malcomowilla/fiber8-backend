class RemoteWinboxExpiryJob < ApplicationJob
  queue_as :default

  def perform(router_id, port)
    router = NasRouter.find_by(id: router_id)
    return unless router
    return unless router.winbox_relay_port == port # a newer session already replaced this port

    dnat_out, dnat_err, dnat_status = Open3.capture3(
      'iptables', '-t', 'nat', '-D', 'PREROUTING', '-p', 'tcp',
      '--dport', port.to_s, '-j', 'DNAT',
      '--to-destination', "#{router.ip_address}:8291"
    )
    Rails.logger.info("[WinBox relay teardown] DNAT delete status=#{dnat_status.exitstatus} stdout=#{dnat_out} stderr=#{dnat_err}")

    masq_out, masq_err, masq_status = Open3.capture3(
      'iptables', '-t', 'nat', '-D', 'POSTROUTING', '-p', 'tcp',
      '-d', router.ip_address, '--dport', '8291', '-j', 'MASQUERADE'
    )
    Rails.logger.info("[WinBox relay teardown] MASQUERADE delete status=#{masq_status.exitstatus} stdout=#{masq_out} stderr=#{masq_err}")

    unless dnat_status.success? && masq_status.success?
      Rails.logger.error("[WinBox relay teardown] FAILED to fully remove rules for router #{router.id} port #{port} — manual cleanup may be needed")
    end

    router.update!(winbox_relay_port: nil, winbox_relay_expires_at: nil)
  end
end