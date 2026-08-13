class RemoteWireguardExecutor
  SSH_HOST = "ubuntu@13.50.245.40".freeze
  SSH_KEY  = File.expand_path("~/.ssh/aws_wireguard").freeze
  SSH_OPTS = "-i #{SSH_KEY} -o StrictHostKeyChecking=no -o ConnectTimeout=5".freeze
  WG_INTERFACE = "wg0".freeze

  class << self
    def exec(command)
      full_cmd = "ssh #{SSH_OPTS} #{SSH_HOST} #{Shellwords.escape(command)}"
      result = `#{full_cmd}`

      unless $?.success?
        Rails.logger.error "[RemoteWireguardExecutor] command failed (#{$?.exitstatus}): #{command}"
      end

      result
    end

    def wg(args)
      exec("sudo wg #{args}")
    end

    def route_add(ip)
      return if ip.blank?

      exec("sudo ip route add #{Shellwords.escape(ip)} dev #{WG_INTERFACE}")
    end

    def route_del(ip)
      return if ip.blank?

      exec("sudo ip route del #{Shellwords.escape(ip)} dev #{WG_INTERFACE}")
    end

    def tcp_reachable?(ip, port = 80, timeout_sec = 3)
      check_cmd = "timeout #{timeout_sec} bash -c 'cat < /dev/null > /dev/tcp/#{ip}/#{port}' && echo OK || echo FAIL"
      exec(check_cmd).strip.include?("OK")
    end

    # Generates a fresh WireGuard keypair on the AWS box in one round-trip.
    # Returns [private_key, public_key].
    def generate_keypair
      output = exec('priv=$(wg genkey); pub=$(echo "$priv" | wg pubkey); echo "$priv"; echo "$pub"')
      lines = output.lines.map(&:strip).reject(&:blank?)
      raise "Failed to generate WireGuard keypair (unexpected output: #{output.inspect})" unless lines.size == 2

      [lines[0], lines[1]]
    end

    def server_public_key
      wg("show #{WG_INTERFACE} public-key").strip
    end
  end
end