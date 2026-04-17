

module Wireguard
  class PeerCheck
    def initialize(interface: 'wg0')
      @interface = interface
    end

    def call(public_key)
      return error('public_key is required') if public_key.blank?

      output = `wg show #{@interface} dump`

      return error('wg command failed') if output.blank?

      peer = parse_peers(output).find { |p| p[:public_key] == public_key }

      return { exists: false } unless peer

      {
        exists: true,
        connected: connected?(peer[:latest_handshake]),
        latest_handshake: peer[:latest_handshake],
        rx: peer[:rx],
        tx: peer[:tx],
        endpoint: peer[:endpoint],
        allowed_ips: peer[:allowed_ips]
      }
    rescue => e
      error(e.message)
    end

    private

    def parse_peers(output)
      lines = output.split("\n")[1..] || [] # skip interface line

      lines.map do |line|
        pk, _, endpoint, allowed_ips, handshake, rx, tx, _ = line.split("\t")

        {
          public_key: pk,
          endpoint: endpoint,
          allowed_ips: allowed_ips,
          latest_handshake: handshake.to_i,
          rx: rx.to_i,
          tx: tx.to_i
        }
      end
    end

    def connected?(handshake)
      return false if handshake.zero?

      Time.now.to_i - handshake < 120
    end

    def error(message)
      { error: message }
    end
  end
end