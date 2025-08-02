class RadAcctObserver < ActiveRecord::Observer
  observe :rad_acct

  def after_commit(record)
    record.broadcast_radacct_stats
  end
end
