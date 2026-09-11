class MikrotikProfileSyncService
  class SyncError < StandardError; end

  def self.sync(package, package_router)
    new(package, package_router).sync
  end

  def self.delete(package_router)
    new(package_router.package, package_router).delete
  end

  def initialize(package, package_router)
    @package = package
    @pr = package_router
  end

  def sync
    router = @pr.nas_router
    pool   = @pr.ip_pool
    client = connect(router)

    name = @package.effective_profile_name
    body = profile_attrs(name, pool)

    found = find_by_id(client) || find_by_name(client, name)

    if found
      profile_id = extract_word(found, '.id')
      client.talk(['/ppp/profile/set', "=.id=#{profile_id}", *body])
    else
      client.talk(['/ppp/profile/add', *body])
      reply = client.talk(['/ppp/profile/print', "?name=#{name}"])
      profile_id = extract_word(reply.find { |s| s.first == '!re' }, '.id')
    end

    @pr.update!(
      mikrotik_ppp_profile_id: profile_id,
      synced: true,
      sync_error: nil,
      last_synced_at: Time.current
    )
  rescue RouterosApiClient::ApiError => e
    @pr.update!(synced: false, sync_error: e.message)
    raise SyncError, e.message
  ensure
    client&.close
  end

  def delete
    router = @pr.nas_router
    client = connect(router)

    found = find_by_id(client) || find_by_name(client, @package.effective_profile_name)
    return unless found # already gone — nothing to clean up

    profile_id = extract_word(found, '.id')
    client.talk(['/ppp/profile/remove', "=.id=#{profile_id}"])
  rescue RouterosApiClient::ApiError => e
    raise SyncError, e.message
  ensure
    client&.close
  end

  private

  def connect(router)
    RouterosApiClient.new(router.ip_address, router.username, router.password).connect
  end

  def find_by_id(client)
    return nil if @pr.mikrotik_ppp_profile_id.blank?
    reply = client.talk(['/ppp/profile/print', "?.id=#{@pr.mikrotik_ppp_profile_id}"])
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
  def profile_attrs(name, pool)
    rate = "#{@package.upload_limit}M/#{@package.download_limit}M"
    session_timeout = validity_string

    attrs = [
      "=name=#{name}",
      "=local-address=#{pool.gateway}",
      "=remote-address=#{pool.name}", # references the pool object on the router
      "=rate-limit=#{rate_with_burst(rate)}",
      "=session-timeout=#{session_timeout}",
      "=only-one=yes"
    ]
    attrs
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