class MikrotikPoolSyncService
  class SyncError < StandardError; end

  def self.sync(ip_pool)
    new(ip_pool).sync
  end

  def self.suggest_range(account)
    new(nil).suggest_range(account)
  end

  def initialize(ip_pool)
    @ip_pool = ip_pool
  end

  def sync
    router = @ip_pool.nas_router
    client = RouterosApiClient.new(router.ip_address, router.username, router.password).connect

    ranges = "#{@ip_pool.ip_range_start}-#{@ip_pool.ip_range_end}"
    existing = client.talk(['/ip/pool/print', "?name=#{@ip_pool.name}"])
    found = existing.find { |sentence| sentence.first == '!re' }

    if found
      pool_id = extract_word(found, '.id')
      client.talk(['/ip/pool/set', "=.id=#{pool_id}", "=ranges=#{ranges}"])
    else
      client.talk(['/ip/pool/add', "=name=#{@ip_pool.name}", "=ranges=#{ranges}"])
      reply = client.talk(['/ip/pool/print', "?name=#{@ip_pool.name}"])
      pool_id = extract_word(reply.find { |s| s.first == '!re' }, '.id')
    end

    used_reply = client.talk(['/ip/pool/used/print', "?pool=#{@ip_pool.name}"])
    used_count = used_reply.count { |s| s.first == '!re' }

    @ip_pool.update!(
      synced: true,
      last_synced_at: Time.current,
      mikrotik_pool_id: pool_id,
      used_ips: used_count
    )
  rescue RouterosApiClient::ApiError => e
    @ip_pool.update!(synced: false)
    raise SyncError, e.message
  ensure
    client&.close
  end

  # Finds a free /19 block (8,192 addresses) in the 10.x.x.x range that
  # doesn't overlap any pool the tenant already has.
  def suggest_range(account)
    used_networks = account.ip_pools.map do |pool|
      IPAddr.new("#{pool.ip_range_start}/19").to_range.first
    rescue IPAddr::Error
      nil
    end.compact

    block_size = 2**13 # /19
    candidate = IPAddr.new('10.0.0.0').to_i

    loop do
      network = IPAddr.new(candidate, Socket::AF_INET).mask(19)
      unless used_networks.include?(network.to_range.first)
        start_ip = IPAddr.new(network.to_i + 10, Socket::AF_INET)
        end_ip   = IPAddr.new(network.to_i + block_size - 3, Socket::AF_INET)
        return {
          ip_range_start: start_ip.to_s,
          ip_range_end: end_ip.to_s,
          subnet_mask: '255.255.224.0',
          gateway: IPAddr.new(network.to_i + 1, Socket::AF_INET).to_s
        }
      end
      candidate += block_size
      raise SyncError, 'No free /19 block available in 10.0.0.0/8' if candidate > IPAddr.new('10.255.255.255').to_i
    end
  end

  private

  def extract_word(sentence, key)
    word = sentence&.find { |w| w.start_with?("=#{key}=") }
    word&.sub("=#{key}=", '')
  end
end