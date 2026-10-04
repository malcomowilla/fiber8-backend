
module CollectorAuth
  extend ActiveSupport::Concern

  COOKIE = :jwt_collector

  included do
    set_current_tenant_through_filter
    skip_before_action :enforce_ip_allowlist, raise: false
    before_action :set_tenant
  end

  private

  def set_tenant
    return render json: { error: "Please sign in to continue." }, status: :unauthorized unless current_collector

    set_current_tenant(@collector_account)
  end

  # The collector admin is a normal User with role "collector_admin"
  def current_collector
    return @current_collector if defined?(@current_collector)

    @current_collector = find_collector_from_cookie
  end

  def find_collector_from_cookie
    token = cookies.encrypted.signed[COOKIE]
    return nil if token.blank?

    payload = JWT.decode(token, ENV["JWT_SECRET"], true, algorithm: "HS256").first
    user = ActsAsTenant.without_tenant { User.find_by(id: payload["user_id"], role: "collector_admin") }
    account = user && Account.find_by(id: user.account_id, account_type: "collector", status: "active")
    return nil unless account

    @collector_account = account
    user
  rescue JWT::DecodeError
    nil
  end

  # 30 days, so a page refresh never logs them out
  def sign_in_collector(user)
    token = JWT.encode({ user_id: user.id, exp: 30.days.from_now.to_i }, ENV["JWT_SECRET"], "HS256")
    cookies.encrypted.signed[COOKIE] = {
      value: token, httponly: true, secure: Rails.env.production?, same_site: :lax, expires: 30.days.from_now
    }
  end

  def sign_out_collector
    cookies.delete(COOKIE)
  end
end