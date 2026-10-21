class CallCenterIvrController < ApplicationController

  
  def show
    return head :unauthorized unless ENV["CALL_CENTER_IVR_TOKEN"].present? &&
      ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, ENV["CALL_CENTER_IVR_TOKEN"])

    account = Account.find_by(id: params[:account_id])
    return head :not_found unless account

    ActsAsTenant.with_tenant(account) do
      s = CallCenterSetting.first_or_create!
      render json: {
        open: s.open_now?,
        open_message: s.open_message,
        closed_message: s.closed_message,
        hold_message: s.hold_message.presence || "Please hold while we connect you.",
        hold_music_url: s.hold_music_url,
        record_calls: s.record_calls,
        announce_recording: s.record_calls && s.announce_recording
      }
    end
  end
end