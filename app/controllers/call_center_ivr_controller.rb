class CallCenterIvrController < ActionController::API
  before_action :authenticate_pbx
  before_action :set_account
    set_current_tenant_through_filter


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
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
     ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Account not found' }, status: :not_found
  end
end