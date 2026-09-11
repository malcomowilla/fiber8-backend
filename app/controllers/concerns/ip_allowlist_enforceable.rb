# module IpAllowlistEnforceable
#   extend ActiveSupport::Concern
#   require 'ipaddr'

#   included do
#     before_action :enforce_ip_allowlist
#   end

#   private

#   # def enforce_ip_allowlist
#   #   return unless @account

#   #   setting = GeneralSetting.find_by(account_id: @account.id)
#   #   return if setting.blank? || setting.allowed_ips.blank?

#   #   allowed_entries = setting.allowed_ips.to_s.split(',').map(&:strip).reject(&:empty?)
#   #   return if allowed_entries.empty?

#   #   unless allowed_entries.any? { |entry| ip_in_range?(request.remote_ip, entry) }
#   #     render json: { error: 'Access denied: your IP address is not permitted' }, status: :forbidden
#   #   end
#   # end


# def enforce_ip_allowlist
#   return unless @account

#   setting = GeneralSetting.find_by(account_id: @account.id)
#   return if setting.blank? || setting.allowed_ips.blank?

#   allowed_entries = Array(setting.allowed_ips).map(&:to_s).map(&:strip).reject(&:empty?)
#   return if allowed_entries.empty?

#   unless allowed_entries.any? { |entry| ip_in_range?(request.remote_ip, entry) }
#     render json: { error: 'Access denied: your IP address is not permitted' }, status: :forbidden
#   end
# end



#   def ip_in_range?(client_ip, entry)
#     IPAddr.new(entry).include?(IPAddr.new(client_ip))
#   rescue IPAddr::Error
#     false
#   end
# end
# 


module IpAllowlistEnforceable
  extend ActiveSupport::Concern
  require 'ipaddr'

  included do
    before_action :enforce_ip_allowlist
  end

  private

  # def enforce_ip_allowlist
  #   account = current_tenant_account
  #   return unless account

  #   setting = GeneralSetting.find_by(account_id: account.id)
  #   return if setting.blank? || setting.allowed_ips.blank?

  #   allowed_entries = Array(setting.allowed_ips).map(&:to_s).map(&:strip).reject(&:empty?)
  #   return if allowed_entries.empty?

  #   unless allowed_entries.any? { |entry| ip_in_range?(request.remote_ip, entry) }
  #     render json: { error: 'Access denied: your IP address is not permitted' }, status: :forbidden
  #   end
  # end



def enforce_ip_allowlist
  account = current_tenant_account
  return unless account

  setting = GeneralSetting.find_by(account_id: account.id)
  return if setting.blank? || setting.allowed_ips.blank?

  blocked_entries = Array(setting.allowed_ips).map(&:to_s).map(&:strip).reject(&:empty?)
  return if blocked_entries.empty?

  if blocked_entries.any? { |entry| ip_in_range?(request.remote_ip, entry) }
    render json: { error: 'Access denied: your IP address has been blocked' }, status: :forbidden
  end
end



  # Resolves the tenant directly from the request, independent of whatever
  # @account-setting before_action each controller happens to define.
  def current_tenant_account
    @account ||= Account.find_by(subdomain: request.headers['X-Subdomain'])
  end

  def ip_in_range?(client_ip, entry)
    IPAddr.new(entry).include?(IPAddr.new(client_ip))
  rescue IPAddr::Error
    false
  end
end