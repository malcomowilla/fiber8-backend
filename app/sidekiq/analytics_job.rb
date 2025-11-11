class AnalyticsJob
  include Sidekiq::Job
  queue_as :default
  # Optional lock if using sidekiq-lock gem
  # sidekiq_options lock: :until_executed, lock_timeout: 0

  def perform
    Account.find_each do |tenant|
      ActsAsTenant.with_tenant(tenant) do
        batch = []

        500.times do
          event_json = $redis.lpop("analytics_events")
          break unless event_json
          event_hash = JSON.parse(event_json)

          # Add account_id for multi-tenant support
          event_hash["account_id"] = tenant.id

          # Ensure timestamp is parsed
          event_hash["timestamp"] = Time.parse(event_hash["timestamp"]) if event_hash["timestamp"]

          batch << event_hash
        end

        # Skip if batch is empty
        next if batch.empty?

        # Bulk insert all events in one query
        AnalyticsEvent.insert_all(batch)
      end
    end
  end
end
