class CdrTenantTagJob
  include Sidekiq::Job
  queue_as :default

  BATCH = 1000

  def perform
    owners   = SipExtension.unscoped.pluck(:pbx_id, :account_id).to_h
    accounts = Account.pluck(:id).to_set

    Cdr.unscoped.where(account_id: nil)
       .select(:uniqueid, :accountcode, :channel, :dstchannel)
       .find_in_batches(batch_size: BATCH) do |rows|
      by_account = Hash.new { |h, k| h[k] = [] }

      rows.each do |r|
        account_id = account_for(r, owners, accounts)
        by_account[account_id] << r.uniqueid if account_id
      end

      by_account.each do |account_id, ids|
        Cdr.unscoped.where(uniqueid: ids, account_id: nil).update_all(account_id: account_id)
      end
    end
  rescue StandardError => e
    Rails.logger.error("[CDR] tenant tagging failed: #{e.class}: #{e.message}")
  end

  private

  # Only ever returns an id that really owns the extension, never a raw parsed number.
  def account_for(row, owners, accounts)
    [row.channel, row.dstchannel].each do |ch|
      pbx = PbxId.from_channel(ch)
      return owners[pbx] if pbx && owners[pbx]
    end

    code = row.accountcode.to_s
    id = code.to_i if code.match?(/\A\d{1,#{PbxId::WIDTH}}\z/)
    id if id && accounts.include?(id)
  end
end