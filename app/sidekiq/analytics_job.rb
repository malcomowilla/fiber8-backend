class AnalyticsJob
  include Sidekiq::Job
  queue_as :default

  def perform
    Rails.logger.info "=== AnalyticsJob started ==="

    batch = []

    500.times do
      raw = $redis.lpop("analytics_events")
      break unless raw

      Rails.logger.info "Popped raw event: #{raw.inspect}"

      h = JSON.parse(raw) rescue (Rails.logger.error "JSON parse failed! raw=#{raw}" ; next)

      h["timestamp"] = Time.parse(h["timestamp"]) if h["timestamp"]

      batch << h
    end

    if batch.empty?
      Rails.logger.info "No events to insert — batch empty"
      return
    end

    Rails.logger.info "Inserting #{batch.size} analytics events..."

    begin
      AnalyticsEvent.insert_all(batch)
      Rails.logger.info "✅ Insert successful"
    rescue => e
      Rails.logger.error "❌ insert_all failed: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    end

    Rails.logger.info "=== AnalyticsJob finished ==="
  end
end
