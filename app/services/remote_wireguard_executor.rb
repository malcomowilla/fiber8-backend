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





    # Checks TCP reachability for many IPs in a single SSH round-trip.
# Returns { ip => { reachable: true/false, latency_ms: Float|nil, message: String } }
def batch_tcp_check(ip_port_pairs, timeout_sec = 2)
  return {} if ip_port_pairs.empty?

  script = +"#!/usr/bin/env bash\n"
  ip_port_pairs.each do |ip, port|
    script << <<~SH
      start=$(date +%s%3N)
      if timeout #{timeout_sec} bash -c 'cat < /dev/null > /dev/tcp/#{ip}/#{port}' 2>/tmp/err_#{ip.gsub('.', '_')}; then
        end=$(date +%s%3N)
        echo "#{ip}|OK|$((end-start))"
      else
        echo "#{ip}|FAIL|$(cat /tmp/err_#{ip.gsub('.', '_')} 2>/dev/null | tr -d '\\n')"
      end
      rm -f /tmp/err_#{ip.gsub('.', '_')}
    SH
  end

  output = exec_script(script)

  results = {}
  output.each_line do |line|
    ip, status, extra = line.strip.split("|", 3)
    next unless ip

    results[ip] =
      if status == "OK"
        { reachable: true, latency_ms: extra.to_f, message: "TCP connection successful (#{extra} ms)" }
      else
        { reachable: false, latency_ms: nil, message: "TCP connection failed: #{extra}" }
      end
  end

  results
end

# Like `exec`, but writes the command to a temp script on the remote host
# and runs it, so multi-line bash (loops, conditionals) survives the SSH hop
# without escaping nightmares.
def exec_script(script_body)
  encoded = Base64.strict_encode64(script_body)
  remote_cmd = "echo #{encoded} | base64 -d | bash"
  full_cmd = "ssh #{SSH_OPTS} #{SSH_HOST} #{Shellwords.escape(remote_cmd)}"
  result = `#{full_cmd}`

  unless $?.success?
    Rails.logger.error "[RemoteWireguardExecutor] script failed (#{$?.exitstatus})"
  end

  result
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