class PaymentGatewaySettingsController < ApplicationController
  include PaymentGatewayVerifiable

  set_current_tenant_through_filter
  before_action :set_tenant

  VALID_GATEWAYS = %w[mpesa payhero tuma paystack sasapay].freeze

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /api/payment_gateway_settings  =>  { "hotspot": "payhero" }
  def show
    setting = PaymentGatewaySetting.find_by(account_id: @account.id, use_case: 'hotspot')
    render json: { hotspot: setting&.gateway || 'mpesa' }
  end

  # PATCH /api/payment_gateway_settings  { gateways: { hotspot: "payhero" } }
  def update
    gateway = (params.dig(:gateways, :hotspot) || params[:gateway]).to_s

    unless VALID_GATEWAYS.include?(gateway)
      return render json: { error: 'Invalid gateway' }, status: :unprocessable_entity
    end

    PaymentGatewaySetting.transaction do
      %w[hotspot tv_plans].each do |use_case|
        setting = PaymentGatewaySetting.find_or_initialize_by(account_id: @account.id, use_case: use_case)
        setting.gateway = gateway
        setting.save!
      end
    end

    render json: { hotspot: gateway }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end


