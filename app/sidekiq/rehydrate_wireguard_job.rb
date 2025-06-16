class RehydrateWireguardJob
  include Sidekiq::Job
    queue_as :default


   def perform
    Rails.logger.info "Rehydrating wireguard"
    WireguardPeer.find_each do |peer|
      `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips}"`
    end
  end
end




