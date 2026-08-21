# app/controllers/payment_gateway_settings_controller.rb
class PaymentGatewaySettingsController < ApplicationController
  include PaymentGatewayVerifiable

  set_current_tenant_through_filter
  before_action :set_tenant

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def show
    settings = PaymentGatewaySetting.where(account_id: @account.id)
    render json: settings.each_with_object({}) { |s, h| h[s.use_case] = s.gateway }
  end

  def update
    result = {}
    (params[:gateways] || {}).each do |use_case, gateway|
      next unless %w[hotspot tv_plans].include?(use_case.to_s)
      next unless %w[mpesa tuma paystack sasapay].include?(gateway.to_s)

      setting = PaymentGatewaySetting.find_or_initialize_by(account_id: @account.id, use_case: use_case)
      setting.gateway = gateway
      setting.save!
      result[use_case] = setting.gateway
    end
    render json: result, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end