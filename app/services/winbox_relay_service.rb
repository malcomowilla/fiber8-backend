class WinboxRelayService
  CONF_DIR = "/etc/haproxy/conf.d".freeze
  PORT_RANGE = (25_000..25_019).freeze # must match the rathole services

  class RelayError < StandardError; end

  def self.open(router, ttl: 15.minutes)
    new(router).open(ttl: ttl)
  end

  def self.close(router, port)
    new(router).close(port)
  end

  def initialize(router)
    @router = router
  end

  def open(ttl: 15.minutes)
    unless @router.ip_address.to_s.match?(/\A[\w.\-]+\z/)
      raise RelayError, "Invalid router address"
    end

    port = nil
    expires_at = ttl.from_now

    PORT_RANGE.to_a.shuffle.first(10).each do |candidate|
      begin
        @router.update!(winbox_relay_port: candidate, winbox_relay_expires_at: expires_at)
        port = candidate
        break
      rescue ActiveRecord::RecordNotUnique
        next
      end
    end

    raise RelayError, "Could not allocate a relay port, try again" unless port

    write_listen_block(port)
    RemoteWinboxExpiryJob.set(wait: ttl).perform_later(@router.id, port)

    port
  end

  def close(port)
    path = conf_path(port)
    File.delete(path) if File.exist?(path)

    return unless @router.winbox_relay_port == port

    @router.update!(winbox_relay_port: nil, winbox_relay_expires_at: nil)
  end

  private

  def conf_path(port)
    File.join(CONF_DIR, "winbox_#{Integer(port)}.cfg")
  end

  def write_listen_block(port)
    File.write(conf_path(port), <<~CFG)
      listen winbox_#{port}
          mode tcp
          bind 127.0.0.1:#{port}
          server winbox_target #{@router.ip_address}:8291
    CFG
  end
end