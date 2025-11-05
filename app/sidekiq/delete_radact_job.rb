

require 'net/http'
require 'uri'
require 'json'

class DeleteRadactJob
  include Sidekiq::Job
  queue_as :default

  def perform
    # Get all *existing* account_ids
    valid_account_ids = Account.pluck(:id)

    # Find radacct that points to non-existent account
    RadAcct.unscoped.where.not(account_id: valid_account_ids).find_each do |radacct|
      Rails.logger.info "Deleting RadAcct ID=#{radacct.id}, invalid account_id=#{radacct.account_id}"
      radacct.destroy!
            Rails.logger.info "Deleted RadAcct ID=#{radacct.id}, invalid account_id=#{radacct.account_id}"

    end
  end
end