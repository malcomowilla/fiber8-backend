class AnalyticsJob
  include Sidekiq::Job
  queue_as :default

  def perform
    batch = []

    500.times do
      raw = $redis.lpop("analytics_events")
      break unless raw

      h = JSON.parse(raw)
      h["timestamp"] = Time.parse(h["timestamp"]) if h["timestamp"]
      batch << h
    end

    return if batch.empty?

    AnalyticsEvent.insert_all(batch)
  end
end