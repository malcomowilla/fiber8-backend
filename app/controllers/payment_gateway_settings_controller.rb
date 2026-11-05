class PaymentGatewaySettingsController < ApplicationController
  include PaymentGatewayVerifiable

  set_current_tenant_through_filter
  before_action :set_tenant

  VALID_GATEWAYS = PaymentGatewaySetting::GATEWAYS

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /api/payment_gateway_settings
  # => { hotspot: "kcb_buni", tv_plans: "mpesa", available: { kcb_buni: true } }
  def show
    render json: {
      hotspot:  PaymentGatewaySetting.active_gateway_for(@account.id, 'hotspot'),
      tv_plans: PaymentGatewaySetting.active_gateway_for(@account.id, 'tv_plans'),
      available: { kcb_buni: KcbBuniService.configured? }
    }
  end

  # PATCH /api/payment_gateway_settings  { gateways: { hotspot: "kcb_buni" } }
  def update
    gateway = (params.dig(:gateways, :hotspot) || params[:gateway]).to_s

    unless VALID_GATEWAYS.include?(gateway)
      return render json: { error: 'Invalid gateway' }, status: :unprocessable_entity
    end

    if gateway == 'kcb_buni' && !KcbBuniService.configured?
      return render json: { error: 'KCB Buni is not configured on the platform yet' },
                    status: :unprocessable_entity
    end

    # Hotspot-only gateways switch the hotspot use case and leave TV plans untouched.
    use_cases = PaymentGatewaySetting::HOTSPOT_ONLY.include?(gateway) ? %w[hotspot] : %w[hotspot tv_plans]

    PaymentGatewaySetting.transaction do
      use_cases.each do |use_case|
        setting = PaymentGatewaySetting.find_or_initialize_by(account_id: @account.id, use_case: use_case)
        setting.gateway = gateway
        setting.save!
      end
    end

    render json: {
      hotspot:  PaymentGatewaySetting.active_gateway_for(@account.id, 'hotspot'),
      tv_plans: PaymentGatewaySetting.active_gateway_for(@account.id, 'tv_plans')
    }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end