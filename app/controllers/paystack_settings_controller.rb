class PaystackSettingsController < ApplicationController
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
    setting = PaystackSetting.find_or_initialize_by(account_id: @account.id)
    render json: serialize(setting)
  end

  def update
    setting = PaystackSetting.find_or_initialize_by(account_id: @account.id)

    attrs = paystack_setting_params
    attrs = attrs.except(:secret_key) if attrs[:secret_key].blank? # don't blank an existing key

    if setting.update(attrs)
      render json: serialize(setting), status: :ok
    else
      render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def test_connection
    setting = PaystackSetting.find_by(account_id: @account.id)
    unless setting&.secret_key.present?
      return render json: { success: false, message: 'No Paystack credentials saved yet' }, status: :unprocessable_entity
    end

    if PaystackService.test_connection(setting)
      render json: { success: true, message: 'Connected to Paystack successfully' }
    else
      render json: { success: false, message: 'Could not authenticate — check your secret key' }, status: :unprocessable_entity
    end
  end

  private

  def serialize(setting)
    {
      id: setting.id,
      public_key: setting.public_key,
      secret_key_present: setting.secret_key.present?,
      secret_key_masked: setting.secret_key.present? ? "#{setting.secret_key[0..6]}••••••••" : nil,
      enabled: setting.enabled,
      use_for_hotspot: setting.use_for_hotspot,
      use_for_tv_plans: setting.use_for_tv_plans,
      ip_whitelist: setting.ip_whitelist || []
    }
  end

  def paystack_setting_params
    params.permit(:public_key, :secret_key, :enabled, :use_for_hotspot, :use_for_tv_plans, ip_whitelist: [])
  end
end