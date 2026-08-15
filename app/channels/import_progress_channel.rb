class ImportProgressChannel < ApplicationCable::Channel
  def subscribed
    job_id    = params[:job_id]
    subdomain = params[:subdomain]
    account   = Account.find_by(subdomain: subdomain)

    # Temporary diagnostic logging — tells us exactly which of the two
    # guard conditions is failing. Remove once the real cause is found.
    Rails.logger.info(
      "[ImportProgressChannel] subscribe attempt — " \
      "raw_params=#{params.to_h.inspect} " \
      "subdomain=#{subdomain.inspect} " \
      "account_found=#{account.present?} account_id=#{account&.id} " \
      "job_id=#{job_id.inspect} job_id_present=#{job_id.present?}"
    )

    unless account && job_id.present?
      Rails.logger.warn "[ImportProgressChannel] rejecting — account_present=#{account.present?} job_id_present=#{job_id.present?}"
      return reject
    end

    stream_from "import_progress:#{account.id}:#{job_id}"
    Rails.logger.info "[ImportProgressChannel] subscribed OK — streaming import_progress:#{account.id}:#{job_id}"
  end

  def unsubscribed
    stop_all_streams
  end
end