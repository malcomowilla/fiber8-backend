class CallCenterIvrController < ApplicationController
  before_action :authenticate_pbx
    before_action :set_account, except: :inbound

    set_current_tenant_through_filter


    def inbound
    did = params[:did].to_s.delete("^0-9")
    setting = did.present? &&
      CallCenterSetting.unscoped.where("? = ANY(string_to_array(did_numbers, ','))", did).first
    account = setting && Account.find_by(id: setting.account_id)
    return render(plain: "") unless account

    ActsAsTenant.with_tenant(account) do
      render plain: [
        PbxId.suffix(account.id),
        setting.open_now? ? "open" : "closed",
        online_agents(account),
        setting.record_calls && setting.announce_recording ? "1" : "0"
      ].join("|")
    end
  end

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

  # Plain text: "record" or "norecord".
  def recording
    ActsAsTenant.with_tenant(@account) do
      render plain: (CallCenterSetting.first&.record_calls ? "record" : "norecord")
    end
  end

  # Spoken greetings: ?kind=open|closed|hold|unreachable|recorded
  def audio
    text = nil
    ActsAsTenant.with_tenant(@account) { text = text_for(params[:kind].to_s) }
    return head :not_found if text.blank?

    send_file TtsService.wav_for(text), type: "audio/wav", disposition: "inline"
  rescue StandardError => e
    Rails.logger.error("[CallCenter] audio failed: #{e.class}: #{e.message}")
    head :not_found
  end

  # The PBX uploads each finished recording here.
  def upload
    file = params[:file]
    path = CallRecordingStore.path(@account.id, params[:uniqueid])
    return head 422 unless path && file.respond_to?(:tempfile)
    return head 413 if file.size > 100.megabytes

    FileUtils.mkdir_p(path.dirname)
    FileUtils.cp(file.tempfile.path, path)
    head :created
  end

  private

  def authenticate_pbx
    expected = ENV["CALL_CENTER_IVR_TOKEN"].to_s
    given = request.headers["X-CC-Token"].presence || params[:token].to_s
    return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(given, expected)

    head :unauthorized
  end

  # account_id arrives zero-padded ("00209") from the dialplan.
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

  # Only agents that are registered right now. If AMI is down, ring everyone and let Dial decide.
  def online_agents(account)
    ids = account.sip_extensions.where(enabled: true).pluck(:pbx_id)
    begin
      live = AsteriskAmi.new.contacts
      ids = ids.select { |id| live[id] && live[id][:available].positive? }
    rescue StandardError => e
      Rails.logger.error("[CallCenter] inbound AMI check failed: #{e.message}")
    end
    ids.map { |id| "PJSIP/#{id}" }.join("&")
  end

  def text_for(kind)
    s = CallCenterSetting.first_or_create!
    case kind
    when "open"        then s.open_message
    when "closed"      then s.closed_message
    when "hold"        then s.hold_message.presence || "Please hold while we connect you."
    when "unreachable" then s.unreachable_message.presence || "The person you are calling is currently unreachable. Please try again later."
    when "recorded"    then "This call may be recorded for quality and training purposes."
    end
  end
end