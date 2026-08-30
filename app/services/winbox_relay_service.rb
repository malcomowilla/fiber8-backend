class WinboxRelayService
  CONF_DIR = "/etc/haproxy/conf.d".freeze

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
    port = nil
    expires_at = ttl.from_now

    10.times do
      candidate = rand(20_000..29_999)
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

  # Deleting the conf file is what makes the port unreachable: the host
  # watcher picks up the delete, revalidates the merged HAProxy config,
  # and reloads. After that, new connections to the port are refused.
  def close(port)
    path = conf_path(port)
    File.delete(path) if File.exist?(path)

    return unless @router.winbox_relay_port == port

    @router.update!(winbox_relay_port: nil, winbox_relay_expires_at: nil)
  end

  private

  def conf_path(port)
    File.join(CONF_DIR, "winbox_#{port}.cfg")
  end

  def write_listen_block(port)
    File.write(conf_path(port), <<~CFG)
      listen winbox_#{port}
          mode tcp
          bind *:#{port}
          server winbox_target #{@router.ip_address}:8291
    CFG
    
  end
end