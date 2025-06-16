class RehydrateWireguardJob
  include Sidekiq::Job
    queue_as :default


   def perform
    WireguardPeer.find_each do |peer|
      system("wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips} persistent-keepalive #{peer.persistent_keepalive || 25}")
    end
  end
end
