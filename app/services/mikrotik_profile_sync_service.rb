class MikrotikProfileSyncService
  class SyncError < StandardError; end

  def self.sync(package)
    new(package).sync
  end

  def self.delete(package)
    new(package).delete
  end

  def initialize(package)
    @package = package
  end

  def sync
    nas = NasRouter.find_by(name: @package.nas_router, account_id: @package.account_id)
    raise SyncError, 'No router specified or router not found' unless nas

    pools = resolve_pools
    raise SyncError, 'No IP pool specified or pool(s) not found' if pools.empty?

    client = connect(nas)
    name = @package.effective_profile_name
    body = profile_attrs(name, pools)

    found = find_by_id(client) || find_by_name(client, name)

    if found
      profile_id = extract_word(found, '.id')
      client.talk(['/ppp/profile/set', "=.id=#{profile_id}", *body])
    else
      client.talk(['/ppp/profile/add', *body])
      reply = client.talk(['/ppp/profile/print', "?name=#{name}"])
      profile_id = extract_word(reply.find { |s| s.first == '!re' }, '.id')
    end

    @package.update!(
      mikrotik_id: profile_id,
      synced: true,
      sync_error: nil,
      last_synced_at: Time.current
    )
  rescue RouterosApiClient::ApiError => e
    @package.update!(synced: false, sync_error: e.message)
    raise SyncError, e.message
  ensure
    client&.close
  end

  def delete
    nas = NasRouter.find_by(name: @package.nas_router, account_id: @package.account_id)
    return unless nas # no router on file — nothing to clean up on a router

    client = connect(nas)
    found = find_by_id(client) || find_by_name(client, @package.effective_profile_name)
    return unless found # already gone on the router

    profile_id = extract_word(found, '.id')
    client.talk(['/ppp/profile/remove', "=.id=#{profile_id}"])
  rescue RouterosApiClient::ApiError => e
    raise SyncError, e.message
  ensure
    client&.close
  end

  private

  # Package.ip_pool holds one or more pool NAMES, comma-separated
  # (e.g. "20Mbps Pool,25Mbps Pool") — same flat-string pattern as
  # Package.nas_router, just allowing more than one value.
  def resolve_pools
    names = @package.ip_pool.to_s.split(',').map(&:strip).reject(&:blank?)
    names.map { |n| IpPool.find_by(name: n, account_id: @package.account_id) }.compact
  end

  def connect(nas)
    RouterosApiClient.new(nas.ip_address, nas.username, nas.password).connect
  end

  def find_by_id(client)
    return nil if @package.mikrotik_id.blank?
    reply = client.talk(['/ppp/profile/print', "?.id=#{@package.mikrotik_id}"])
    reply.find { |s| s.first == '!re' }
  end

  def find_by_name(client, name)
    reply = client.talk(['/ppp/profile/print', "?name=#{name}"])
    reply.find { |s| s.first == '!re' }
  end

  # NOTE on direction: RouterOS rate-limit is "rx-rate/tx-rate" measured from
  # the router's point of view — rx is what the router receives FROM the
  # client (i.e. the client's upload), tx is what it sends TO the client
  # (the client's download). Get this backwards and upload/download limits
  # are silently swapped for every customer on the profile.
  #
  # `pools` is an array — RouterOS accepts a comma-separated list of pool
  # names in remote-address and draws from whichever pool has room, in the
  # order given. local-address uses the first pool's gateway; if pools span
  # different subnets, this account's setup should give them the same
  # gateway or PPPoE clients on later pools may get an unreachable gateway.
  def profile_attrs(name, pools)
    rate = "#{@package.upload_limit}M/#{@package.download_limit}M"

    [
      "=name=#{name}",
      "=local-address=#{pools.first.gateway}",
      "=remote-address=#{pools.map(&:name).join(',')}",
      "=rate-limit=#{rate_with_burst(rate)}",
      "=session-timeout=#{validity_string}",
      "=only-one=yes"
    ]
  end

  def rate_with_burst(base_rate)
    return base_rate unless @package.burst_upload_speed.present? && @package.burst_download_speed.present?

    burst_rate = "#{@package.burst_upload_speed}M/#{@package.burst_download_speed}M"
    threshold  = "#{@package.burst_threshold_upload}M/#{@package.burst_threshold_download}M"
    time       = "#{@package.burst_time}/#{@package.burst_time}"
    "#{base_rate} #{burst_rate} #{threshold} #{time}"
  end

  def validity_string
    case @package.validity_period_units
    when 'days'  then "#{@package.validity}d 00:00:00"
    when 'hours' then "#{@package.validity}:00:00"
    else "#{@package.validity}d 00:00:00"
    end
  end

  def extract_word(sentence, key)
    word = sentence&.find { |w| w.start_with?("=#{key}=") }
    word&.sub("=#{key}=", '')
  end
end