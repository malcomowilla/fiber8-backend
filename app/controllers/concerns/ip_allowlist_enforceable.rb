# app/controllers/concerns/ip_allowlist_enforceable.rb
module IpAllowlistEnforceable
  extend ActiveSupport::Concern
  require 'ipaddr'

  included do
    before_action :enforce_ip_allowlist
  end

  private

  def enforce_ip_allowlist
    return unless @account

    setting = GeneralSetting.find_by(account_id: @account.id)
    return if setting.blank? || setting.allowed_ips.blank?

    allowed_entries = setting.allowed_ips.to_s.split(',').map(&:strip).reject(&:empty?)
    return if allowed_entries.empty?

    unless allowed_entries.any? { |entry| ip_in_range?(request.remote_ip, entry) }
      render json: { error: 'Access denied: your IP address is not permitted' }, status: :forbidden
    end
  end

  def ip_in_range?(client_ip, entry)
    IPAddr.new(entry).include?(IPAddr.new(client_ip))
  rescue IPAddr::Error
    false
  end
end