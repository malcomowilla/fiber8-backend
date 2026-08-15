 
class ImportProgressChannel < ApplicationCable::Channel
  def subscribed
    job_id    = params[:job_id]
    subdomain = params[:subdomain]
    account   = Account.find_by(subdomain: subdomain)
    return reject unless account && job_id.present?
 
    stream_from "import_progress:#{account.id}:#{job_id}"
  end
 
  def unsubscribed
    stop_all_streams
  end
end