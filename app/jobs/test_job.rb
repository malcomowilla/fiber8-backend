class TestJob < ApplicationJob
  queue_as :default
  def perform(*args)
    Rails.logger.info "🔥🔥🔥 TestJob is running with args: #{args.inspect}"
    User.update_all(status: 'testing')
    puts "🔥🔥🔥 TestJob is running with args: #{args.inspect}"
  end
end





