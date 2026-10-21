require "securerandom"

class ProvisionExtensionService
  KINDS = %w[webrtc softphone].freeze

  class << self
    def call(account:, extension:, name:, kind: "webrtc", transport: nil)
      extension = extension.to_s.strip
      name = name.to_s.strip
      kind = kind.to_s.presence || "webrtc"
      transport ||= transport_for(kind)

      return failure("Account is required") unless account
      return failure("Extension must contain 3–5 digits") unless extension.match?(PbxId::SHORT)
      return failure("Name is required") if name.blank?
      return failure("Invalid type") unless KINDS.include?(kind)

      pbx_id = PbxId.build(extension, account.id)
      password = SecureRandom.hex(16)

      SipExtension.transaction do
        if PjsipEndpoint.exists?(id: pbx_id) ||
           PjsipAuth.exists?(id: pbx_id) ||
           PjsipAor.exists?(id: pbx_id)
          raise ActiveRecord::RecordNotUnique
        end

        sip_extension = SipExtension.create!(
          account: account, extension: extension, pbx_id: pbx_id, name: name,
          transport: transport, kind: kind, enabled: true
        )

        PjsipAor.create!(
          id: pbx_id, max_contacts: 3, remove_existing: "yes", qualify_frequency: 60
        )

        PjsipAuth.create!(
          id: pbx_id, auth_type: "userpass", username: pbx_id, password: password
        )

        PjsipEndpoint.create!(endpoint_attributes(sip_extension).merge(id: pbx_id))

        {
          success: true,
          extension: sip_extension,
          credentials: { username: pbx_id, password: password }
        }
      end
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    rescue ActiveRecord::RecordNotUnique
      failure("Extension already exists. Choose another number.")
    rescue ArgumentError => e
      failure(e.message)
    rescue StandardError => e
      log_error("Create", e)
      failure("Could not provision SIP extension.")
    end

    def update(account:, extension:, name: nil, enabled: nil, password: nil, kind: nil)
      sip_extension = find_extension(account, extension)
      return failure("Extension not found") unless sip_extension
      return failure("Invalid type") if kind.present? && !KINDS.include?(kind.to_s)

      pbx_id = sip_extension.pbx_id

      SipExtension.transaction do
        if name.present?
          sip_extension.update!(name: name)
          PjsipEndpoint.find_by(id: pbx_id)&.update!(callerid: "#{sip_extension.name} <#{sip_extension.extension}>")
        end

        PjsipAuth.find_by!(id: pbx_id).update!(password: password) if password.present?

        if kind.present? && kind.to_s != sip_extension.kind
          sip_extension.update!(kind: kind.to_s, transport: transport_for(kind))
          PjsipEndpoint.find_by(id: pbx_id)&.update!(endpoint_attributes(sip_extension))
        end

        if enabled == false
          PjsipEndpoint.where(id: pbx_id).delete_all
          sip_extension.update!(enabled: false)
        elsif enabled == true
          PjsipAuth.find_by!(id: pbx_id)
          PjsipAor.find_by!(id: pbx_id)

          unless PjsipEndpoint.exists?(id: pbx_id)
            PjsipEndpoint.create!(endpoint_attributes(sip_extension).merge(id: pbx_id))
          end

          sip_extension.update!(enabled: true)
        end
      end

      { success: true, extension: sip_extension }
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages.to_sentence)
    rescue StandardError => e
      log_error("Update", e)
      failure("Could not update SIP extension.")
    end

    def reset_password(account:, extension:)
      sip_extension = find_extension(account, extension)
      return failure("Extension not found") unless sip_extension

      password = SecureRandom.hex(16)
      PjsipAuth.find_by!(id: sip_extension.pbx_id).update!(password: password)

      { success: true, credentials: { username: sip_extension.pbx_id, password: password } }
    rescue StandardError => e
      log_error("Reset password", e)
      failure("Could not reset password.")
    end

    # Used by the browser softphone. Only WebRTC extensions are handed out.
    # `extension` in the result is the SIP username (the PBX id), not the short number.
    def credentials(account:, extension:)
      sip_extension = find_extension(account, extension)
      return failure("Extension not found") unless sip_extension
      return failure("Extension is disabled") unless sip_extension.enabled?
      return failure("Extension is not a browser (WebRTC) extension") unless sip_extension.kind == "webrtc"

      auth = PjsipAuth.find_by(id: sip_extension.pbx_id)
      return failure("Extension credentials missing") unless auth

      { success: true, extension: sip_extension.pbx_id, password: auth.password }
    end

    # All extensions with live registration info.
    def list(account:)
      ami_online = true
      contacts = begin
        AsteriskAmi.new.contacts
      rescue StandardError => e
        log_error("List", e)
        ami_online = false
        {}
      end

      items = account.sip_extensions.order(:extension).map do |x|
        c = contacts[x.pbx_id]
        online = x.enabled? && c && c[:available].positive?
        {
          extension: x.extension,
          name: x.name,
          kind: x.kind,
          enabled: x.enabled?,
          registered: x.enabled? && !c.nil?,
          status: !ami_online ? "unknown" : (online ? "online" : "offline"),
          via: c && c[:via],
          ip: c && c[:ip],
          rtt: c && c[:rtt],
          contacts: c ? c[:contacts] : 0
        }
      end

      { ami_online: ami_online, extensions: items }
    end

    def status(account:, extension:)
      sip_extension = find_extension(account, extension)
      return failure("Extension not found") unless sip_extension

      unless sip_extension.enabled?
        return {
          success: true, extension: sip_extension.extension, enabled: false,
          registered: false, status: "offline", reachability: "unknown", contacts: 0
        }
      end

      contact = AsteriskAmi.new.contact_status(extension: sip_extension.pbx_id)

      {
        success: true,
        extension: sip_extension.extension,
        enabled: true,
        registered: contact[:registered],
        status: contact[:status],
        reachability: contact[:reachability],
        contacts: contact[:contacts],
        via: contact[:via]
      }
    rescue StandardError => e
      log_error("Status", e)
      failure("Could not retrieve extension status.")
    end

    def delete(account:, extension:)
      sip_extension = find_extension(account, extension)
      return failure("Extension not found") unless sip_extension

      SipExtension.transaction do
        id = sip_extension.pbx_id

        PjsipEndpoint.where(id: id).delete_all
        PjsipAuth.where(id: id).delete_all
        PjsipAor.where(id: id).delete_all

        sip_extension.destroy!
      end

      { success: true }
    rescue StandardError => e
      log_error("Delete", e)
      failure("Could not delete SIP extension.")
    end

    private

    def find_extension(account, extension)
      account.sip_extensions.find_by(extension: extension.to_s)
    end

    def transport_for(kind)
      kind.to_s == "webrtc" ? "transport-wss" : "transport-udp"
    end

    # Callerid shows the short number; the PBX id never leaves Asterisk and the SIP login.
    # accountcode flows into cdr.accountcode for every call this endpoint makes or receives.
    def endpoint_attributes(x)
      base = {
        transport: x.transport,
        aors: x.pbx_id,
        auth: x.pbx_id,
        context: "from-internal",
        disallow: "all",
        callerid: "#{x.name} <#{x.extension}>",
        accountcode: PbxId.suffix(x.account_id),
        direct_media: "no",
        force_rport: "yes",
        rewrite_contact: "yes",
        rtp_symmetric: "yes"
      }

      if x.kind.to_s == "webrtc"
        base.merge(allow: "ulaw,alaw", webrtc: "yes", dtls_auto_generate_cert: "yes")
      else
        base.merge(allow: "ulaw,alaw")
      end
    end

    def failure(message)
      { success: false, error: message }
    end

    def log_error(action, error)
      Rails.logger.error("[Asterisk] #{action} extension failed: #{error.class}: #{error.message}")
    end
  end
end