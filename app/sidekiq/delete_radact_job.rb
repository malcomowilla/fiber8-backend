require 'net/http'
require 'uri'
require 'json'

class DeleteRadactJob
  include Sidekiq::Job
  queue_as :default

  def perform
    # Get all *existing* account_ids
    valid_account_ids = Account.pluck(:id)

    # -------------------------------
    # DELETE INVALID RadAcct ENTRIES
    # -------------------------------
    RadAcct.unscoped.where.not(account_id: valid_account_ids).find_each do |radacct|
      Rails.logger.info "Deleting RadAcct ID=#{radacct.id}, invalid account_id=#{radacct.account_id}"
      radacct.destroy!
      Rails.logger.info "Deleted RadAcct ID=#{radacct.id}"
    end

    # -------------------------------
    # DELETE INVALID Radcheck ENTRIES
    # -------------------------------
    Radcheck.where.not(account_id: valid_account_ids).find_each do |radcheck|
      Rails.logger.info "Deleting Radcheck ID=#{radcheck.id}, invalid account_id=#{radcheck.account_id}"
      radcheck.destroy!
      Rails.logger.info "Deleted Radcheck ID=#{radcheck.id}"
    end
  end
end
