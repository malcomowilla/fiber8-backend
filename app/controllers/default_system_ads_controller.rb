class DefaultSystemAdsController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant

  VALID_AD_IDS = %w[advertise_with_us reach_customers fast_internet].freeze

  def index
    settings = DefaultSystemAdSetting.where(account: ActsAsTenant.current_tenant)
    render json: settings.map { |s| { ad_id: s.ad_id, enabled: s.enabled } }
  end

  def toggle
    ad_id = params[:id]
    return render json: { error: 'Unknown ad' }, status: :unprocessable_entity unless VALID_AD_IDS.include?(ad_id)

    account = ActsAsTenant.current_tenant
    enabled = ActiveModel::Type::Boolean.new.cast(params[:enabled])

    ActiveRecord::Base.transaction do
      # only one active at a time
      if enabled
        DefaultSystemAdSetting.where(account: account).update_all(enabled: false)
      end
      setting = DefaultSystemAdSetting.find_or_initialize_by(account: account, ad_id: ad_id)
      setting.update!(enabled: enabled)
    end

    render json: { ad_id: ad_id, enabled: enabled }
  end

  # Called by the hotspot page to know which default ad (if any) to show
  def active
    setting = DefaultSystemAdSetting.find_by(account: ActsAsTenant.current_tenant, enabled: true)
    if setting
      render json: { ad_id: setting.ad_id }
    else
      render json: { ad_id: nil }
    end
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue
    render json: { error: 'Invalid tenant' }, status: :not_found
  end
end
