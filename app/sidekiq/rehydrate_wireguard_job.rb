





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
      # ping_result = `ping -c 1 -W 1 #{tunnel_ip} > /dev/null 2>&1`
      # reachable = $?.success? ? "YES" : "NO"
  reachable = tcp_reachable?(tunnel_ip) ? "YES" : "NO"
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



  private


  def tcp_reachable?(ip, port = 80, timeout_sec = 3)
  Timeout.timeout(timeout_sec) do
    begin
      socket = TCPSocket.new(ip, port)
      socket.close
      true
    rescue Errno::ECONNREFUSED
      # Host is reachable but port closed → still reachable
      true
    rescue StandardError
      false
    end
  end
rescue Timeout::Error
  false
end





end
















# class RehydrateWireguardJob
#   include Sidekiq::Job
#   queue_as :default

#   SSH_HOST = "ubuntu@13.50.245.40".freeze
#   SSH_KEY  = File.expand_path("~/.ssh/aws_wireguard").freeze
#   SSH_OPTS = "-i #{SSH_KEY} -o StrictHostKeyChecking=no -o ConnectTimeout=5".freeze
#   WG_INTERFACE = "wg0".freeze

#   def perform
#     # ------------------------------------------
#     # STEP 1 — Apply IP settings to WireGuard (remote)
#     # ------------------------------------------
#     WireguardPeer.find_each do |peer|
#       allowed_ips =
#         if peer.private_ip.present?
#           "#{peer.allowed_ips},#{peer.private_ip}"
#         else
#           peer.allowed_ips
#         end

#       remote_wg("set #{WG_INTERFACE} peer #{peer.public_key} allowed-ips #{allowed_ips}")
#     end

#     # ------------------------------------------
#     # STEP 2 — Parse `wg show wg0` (remote)
#     # ------------------------------------------
#     output = remote_wg("show #{WG_INTERFACE}")
#     wg_peers = []
#     current = {}

#     output.each_line do |line|
#       line = line.strip

#       if line.start_with?("peer:")
#         wg_peers << current unless current.empty?
#         current = { public_key: line.split(": ", 2)[1] }
#       elsif line.start_with?("endpoint:")
#         current[:endpoint] = line.split(": ", 2)[1]
#       elsif line.start_with?("allowed ips:")
#         current[:allowed_ips] = line.split(": ", 2)[1]
#       elsif line.start_with?("latest handshake:")
#         current[:handshake] = line.split(": ", 2)[1]
#       elsif line.start_with?("transfer:")
#         parts = line.split(": ", 2)[1]
#         recv, sent = parts.split(",")
#         current[:received] = recv.strip
#         current[:sent] = sent.strip
#       end
#     end

#     wg_peers << current unless current.empty?

#     # ------------------------------------------
#     # STEP 3 — Match DB peers and update status
#     # ------------------------------------------
#     wg_peers.each do |wg_peer|
#       db_peer = WireguardPeer.find_by(public_key: wg_peer[:public_key])
#       next unless db_peer

#       allowed_ip = db_peer.allowed_ips

#       tunnel_ip =
#         if db_peer.private_ip.present?
#           ip, mask = db_peer.private_ip.split("/")

#           if mask.to_i == 32
#             ip
#           else
#             parts = ip.split(".")
#             parts[3] = "1"
#             parts.join(".")
#           end
#         else
#           base, mask = allowed_ip.split("/")

#           if mask.to_i == 32
#             base
#           else
#             parts = base.split(".")
#             parts[3] = "1"
#             parts.join(".")
#           end
#         end

#       handshake = wg_peer[:handshake].to_s.downcase

#       is_connected = !(handshake == "0 seconds ago" ||
#                        handshake.include?("never") ||
#                        handshake.empty?)

#       # -----------------------------
#       # Check if tunnel IP reachable — via SSH into the AWS box,
#       # since the Rails host may not have a route to the tunnel IP itself
#       # -----------------------------
#       reachable = remote_tcp_reachable?(tunnel_ip) ? "YES" : "NO"

#       lines = []

#       if is_connected
#         lines << "Connected (#{wg_peer[:endpoint]})"
#       else
#         lines << "Disconnected"
#       end

#       lines << "Tunnel IP: #{tunnel_ip}"
#       lines << "Reachable: #{reachable}"

#       if is_connected && wg_peer[:received].present? && wg_peer[:sent].present?
#         lines << "#{wg_peer[:received]}     #{wg_peer[:sent]}"
#       end

#       if is_connected
#         lines << "Since: #{Time.current.strftime("%Y-%m-%d %H:%M")}"
#       end

#       db_peer.update(status: lines.join("\n"))
#     end
#   end

#   private

#   # Runs a `wg` subcommand on the remote AWS host over SSH and returns stdout.
#   def remote_wg(args)
#     remote_exec("sudo wg #{args}")
#   end

#   # Runs an arbitrary shell command on the remote host over SSH.
#   # Values interpolated into `args` by callers are expected to come from
#   # our own DB records, but we still shell-escape defensively.
#   def remote_exec(command)
#     full_cmd = "ssh #{SSH_OPTS} #{SSH_HOST} #{Shellwords.escape(command)}"
#     result = `#{full_cmd}`

#     unless $?.success?
#       Rails.logger.error "[RehydrateWireguardJob] remote_exec failed (#{$?.exitstatus}): #{command}"
#     end

#     result
#   end

#   # Instead of pinging locally, ask the remote AWS host to attempt a TCP
#   # connect to the tunnel IP (it's the box that actually sits on the VPN).
#   def remote_tcp_reachable?(ip, port = 80, timeout_sec = 3)
#     check_cmd = "timeout #{timeout_sec} bash -c 'cat < /dev/null > /dev/tcp/#{ip}/#{port}' && echo OK || echo FAIL"
#     result = remote_exec(check_cmd)
#     result.strip.include?("OK")
#   end
# end