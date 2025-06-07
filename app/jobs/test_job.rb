class TestJob < ApplicationJob
  queue_as :default
  def perform(*args)
    Rails.logger.info "🔥🔥🔥 TestJob is running with args: #{args.inspect}"
    puts "🔥🔥🔥 TestJob is running with args: #{args.inspect}"
  end
end
