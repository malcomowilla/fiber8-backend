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

    # ------------------------------------------
    # STEP 1 — Apply IP settings to WireGuard
    # ------------------------------------------
    WireguardPeer.find_each do |peer|
      if peer.private_ip.present?
        `wg set #{interface} peer #{peer.public_key} allowed-ips #{peer.allowed_ips},#{peer.private_ip}`
      else
        `wg set #{interface} peer #{peer.public_key} allowed-ips #{peer.allowed_ips}`
      end
    end

    # ------------------------------------------
    # STEP 2 — Parse `wg show wg0`
    # ------------------------------------------
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

    # ------------------------------------------
    # STEP 3 — Match DB peers and update status
    # ------------------------------------------
    wg_peers.each do |wg_peer|
      db_peer = WireguardPeer.find_by(public_key: wg_peer[:public_key])
      next unless db_peer

      # -----------------------------
      # Determine tunnel IP
      # -----------------------------
      # tunnel_ip =
      #   if db_peer.private_ip.present?
      #     db_peer.private_ip
      #   else
      #     db_peer.allowed_ips.split("/").first
      #   end
allowed_ip = db_peer.allowed_ips

tunnel_ip =
  if db_peer.private_ip.present?
    # ----------------------------
    # private_ip may contain "/"
    # ----------------------------
    ip, mask = db_peer.private_ip.split("/")

    if mask.to_i == 32
      ip
    else
      parts = ip.split(".")
      parts[3] = "1"
      parts.join(".")
    end

  else
    # ----------------------------
    # handle allowed_ips normally
    # ----------------------------
    base, mask = allowed_ip.split("/")

    if mask.to_i == 32
      base
    else
      parts = base.split(".")
      parts[3] = "1"
      parts.join(".")
    end
  end


      
      # -----------------------------
      # Check if handshake = connected
      # -----------------------------
      handshake = wg_peer[:handshake].to_s.downcase

      is_connected = !(handshake == "0 seconds ago" ||
                       handshake.include?("never") ||
                       handshake.empty?)

      # -----------------------------
      # Check if tunnel IP reachable
      # -----------------------------
      ping_result = `ping -c 1 -W 1 #{tunnel_ip} > /dev/null 2>&1`
      reachable = $?.success? ? "YES" : "NO"

      # -----------------------------
      # Build status message
      # -----------------------------
      lines = []

      if is_connected
        lines << "Connected (#{wg_peer[:endpoint]})"
      else
        lines << "Disconnected"
      end

      lines << "Tunnel IP: #{tunnel_ip}"
      lines << "Reachable: #{reachable}"

      if is_connected && wg_peer[:received].present? && wg_peer[:sent].present?
        lines << "#{wg_peer[:received]}     #{wg_peer[:sent]}"
      end

      if is_connected
        lines << "Since: #{Time.current.strftime("%Y-%m-%d %H:%M")}"
      end

      db_peer.update(status: lines.join("\n"))
    end
  end
end
