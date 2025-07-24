


class OnlineStatsBroadcastJob 
  include Sidekiq::Job
  queue_as :default

  
  def perform
    # stats = generate_stats # however you get the stats

    ActionCable.server.broadcast("online_stats_channel", { content: 'hello test' })

  rescue => e
    Rails.logger.error "ActionCable Broadcast Failed: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e # still let Sidekiq retry if needed
  end
end
