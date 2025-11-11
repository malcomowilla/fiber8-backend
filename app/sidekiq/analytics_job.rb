class AnalyticsJob
  include Sidekiq::Job
  queue_as :default

  def perform
    batch = []

    500.times do
      event_json = $redis.lpop("analytics_events")
      break unless event_json

      event_hash = JSON.parse(event_json)
      event_hash["timestamp"] = Time.parse(event_hash["timestamp"]) if event_hash["timestamp"]
      batch << event_hash
    end

    return if batch.empty?

    AnalyticsEvent.insert_all([batch])
  end
end
