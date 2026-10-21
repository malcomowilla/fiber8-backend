class CallCenterIvrController < ActionController::API
  before_action :authenticate_pbx
  before_action :set_account

  def show
    ActsAsTenant.with_tenant(@account) do
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

  # Plain text so the dialplan needs no JSON parsing: "record" or "norecord".
  def recording
    ActsAsTenant.with_tenant(@account) do
      s = CallCenterSetting.first
      render plain: (s&.record_calls ? "record" : "norecord")
    end
  end

  private

  def authenticate_pbx
    token = ENV["CALL_CENTER_IVR_TOKEN"].to_s
    return if token.present? && ActiveSupport::SecurityUtils.secure_compare(params[:token].to_s, token)

    head :unauthorized
  end

  # account_id may arrive zero-padded ("00007") from the dialplan.
  def set_account
    @account = Account.find_by(id: params[:account_id].to_s.to_i)
    head :not_found unless @account
  end
end