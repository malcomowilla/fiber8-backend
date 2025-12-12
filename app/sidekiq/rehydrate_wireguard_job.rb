# class RehydrateWireguardJob
#   include Sidekiq::Job
#     queue_as :default


#    def perform
#     Rails.logger.info "Rehydrating wireguard"
#     WireguardPeer.find_each do |peer|
#       # `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips}`
#             if peer.private_ip.nil?
              
#               `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips}`
              
#             else
#                `wg set wg0 peer #{peer.public_key} allowed-ips #{peer.allowed_ips},#{peer.private_ip}`

#             end


#     end




    

#   end





# end











class RehydrateWireguardJob
  include Sidekiq::Job
  queue_as :default

  def perform
    interface = "wg0"

    # ------------------------------------------------------------
    # STEP 1 — APPLY ALLOWED IPs FROM DATABASE TO WIREGUARD
    # ------------------------------------------------------------
    WireguardPeer.find_each do |peer|
      if peer.private_ip.present?
        # allowed_ips + private_ip
        `wg set #{interface} peer #{peer.public_key} allowed-ips #{peer.allowed_ips},#{peer.private_ip}`
      else
        # only allowed_ips
        `wg set #{interface} peer #{peer.public_key} allowed-ips #{peer.allowed_ips}`
      end
    end

    # ------------------------------------------------------------
    # STEP 2 — RUN `wg show wg0` AND PARSE IT
    # ------------------------------------------------------------
    output = `wg show #{interface}`
    wg_peers = []
    current = {}

    output.each_line do |line|
      line = line.strip

      if line.start_with?("peer:")
        wg_peers << current unless current.empty?
        current = { public_key: line.split(": ", 2)[1] }
      elsif line.start_with?("endpoint:")
        current[:endpoint] = line.split(": ", 2)[1]
      elsif line.start_with?("allowed ips:")
        current[:allowed_ips] = line.split(": ", 2)[1]
      elsif line.start_with?("latest handshake:")
        current[:handshake] = line.split(": ", 2)[1]
      elsif line.start_with?("transfer:")
        parts = line.split(": ", 2)[1]
        recv, sent = parts.split(",")
        current[:received] = recv.strip
        current[:sent] = sent.strip
      end
    end

    wg_peers << current unless current.empty?

    # ------------------------------------------------------------
    # STEP 3 — MATCH WITH DB AND UPDATE STATUS COLUMN
    # ------------------------------------------------------------
    wg_peers.each do |wg_peer|
      db_peer = WireguardPeer.find_by(public_key: wg_peer[:public_key])
      next unless db_peer

      tunnel_ip =
        if db_peer.private_ip.present?
          db_peer.private_ip
        else
          db_peer.allowed_ips.split("/").first
        end

      status =  "Connected (#{wg_peer[:endpoint]})\n" \
                "Tunnel IP: #{tunnel_ip}\n" \
                "#{wg_peer[:received]}     #{wg_peer[:sent]}\n" \
                "Since: #{Time.current.strftime("%Y-%m-%d %H:%M")}"

      db_peer.update(status: status)
    end
  end
end

