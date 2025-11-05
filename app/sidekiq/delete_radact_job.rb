class DeleteRadactJob
  include Sidekiq::Job
  queue_as :default

  def perform
    valid_account_ids = Account.pluck(:id)

    RadAcct.unscoped.where.not(account_id: valid_account_ids).find_each do |radacct|
      begin
        Rails.logger.info "Deleting RadAcct ID=#{radacct.id}, invalid account_id=#{radacct.account_id}"

        radacct.destroy!   # This is where it's failing

        Rails.logger.info "✅ Successfully deleted RadAcct ID=#{radacct.id}"
      rescue => e
        Rails.logger.error "❌ Failed to delete RadAcct ID=#{radacct.id}: #{e.class} - #{e.message}"
      end
    end
  end
end
