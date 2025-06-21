
class InactivityCheckJob
  include Sidekiq::Job
  queue_as :default

  def perform
    
    Account.find_each do |account|
      begin
        ActsAsTenant.with_tenant(account) do
          Rails.logger.info "Starting inactivity check for account - Subdomain: #{account.subdomain}"
          
          @my_inactivity = ActsAsTenant.current_tenant.admin_setting
          next unless @my_inactivity # Skip if no settings found

          process_inactivity_checks
        end
      rescue => e
        Rails.logger.error "Error processing account #{account.subddomain}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end

  private

  def process_inactivity_checks
    # Check minutes if minutes value is present
    if @my_inactivity.checkinactiveminutes.present? && @my_inactivity.checkinactiveminutes.to_i > 0
      process_minutes_check
    end
    

    # Check hours if hours value is present
    if @my_inactivity.checkinactivehrs.present? && @my_inactivity.checkinactivehrs.to_i > 0
      process_hours_check
    end

    # Check days if days value is present
    if @my_inactivity.checkinactivedays.present? && @my_inactivity.checkinactivedays.to_i > 0
      process_days_check
    end
  end

  def process_minutes_check
    threshold = @my_inactivity.checkinactiveminutes.to_i.minutes.ago
    Rails.logger.info "Processing minutes check with threshold: #{threshold}"
    mark_inactive(threshold)
  end

  def process_hours_check
    threshold = @my_inactivity.checkinactivehrs.to_i.hours.ago
    Rails.logger.info "Processing hours check with threshold: #{threshold}"
    mark_inactive(threshold)
  end

  def process_days_check
    threshold = @my_inactivity.checkinactivedays.to_i.days.ago
    Rails.logger.info "Processing days check with threshold: #{threshold}"
    mark_inactive(threshold)
  end

  def mark_inactive(threshold)
    admins_affected = User.where('last_activity_active < ?', threshold)
                          # .where(inactive: false)
                          .update_all(inactive: true)
    
    Rails.logger.info "Marked #{admins_affected} admins as inactive (threshold: #{threshold})"
  end
end



