class HotspotSmsTemplatesController < ApplicationController
  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_template, only: [:update, :destroy]

  DEFAULTS = {
    'single_compact' => {
      title: 'Compact',
      message: "{company_name} WiFi\nYour Voucher Code: {voucher_code}\nExpiry: {validity}",
      active: false
    },
    'single_notification' => {
      title: 'Notification',
      message: "Thank you for your purchase!\nPlan: {plan_name}\nVoucher Code: {voucher_code}\nValid for: {validity}",
      active: true
    },
    'multi_compact' => {
      title: 'Compact',
      message: "{company_name} WiFi - {plan_name} ({price})\n{voucher_count} vouchers: {voucher_list}\nValid: {validity}",
      active: false
    },
    'multi_notification' => {
      title: 'Notification',
      message: "Thank you for your purchase!\nYour Voucher Codes:\n{voucher_list}\nValid for: {validity}",
      active: true
    },


'tv_plan_purchase' => {
    title: 'TV Plan Purchase',
    message: "Payment received! Your {plan_name} plan for {device_name} is active until {validity}. " \
              "Manage your devices: {portal_url}. — {company_name}",
    active: true
  },

    
    'expiration' => {
      title: 'Expiration Reminder',
      message: "Hello, your voucher {voucher_code} has expired. Renew now to stay connected. (FROM: {company_name})",
      active: true
    }
  }.freeze

  # GET /api/hotspot_sms_templates
  # Ensures every account always has one row per category (creating the
  # documented defaults on first load) so the frontend never has to guess.
  def index
    existing = HotspotSmsTemplate.where(account_id: @account.id).index_by(&:category)

    DEFAULTS.each do |category, attrs|
      next if existing[category]

      existing[category] = HotspotSmsTemplate.create!(
        account_id: @account.id,
        category: category,
        title: attrs[:title],
        message: attrs[:message],
        active: attrs[:active]
      )
    end

    templates = existing.values.sort_by do |t|
      # `|| 999` keeps this from blowing up if a category (e.g. 'expiration')
      # isn't registered in CATEGORIES yet — unknown categories just sort last
      # instead of crashing the whole endpoint.
      HotspotSmsTemplate::CATEGORIES.index(t.category) || 999
    end

    render json: { templates: templates.map { |t| serialize_template(t) } }
  end

  # PATCH /api/hotspot_sms_templates/:id
  def update
    if @template.update(hotspot_sms_template_params)
      render json: { template: serialize_template(@template) }, status: :ok
    else
      render json: { errors: @template.errors }, status: :unprocessable_entity
    end
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    ActsAsTenant.current_tenant = @account
  end

  # Was previously looking records up by category (derived from the frontend's
  # dash-cased pseudo id) with account scoping commented out. That broke saves,
  # since /index now returns the real numeric primary key as `id` — and it let
  # any tenant edit any other tenant's templates by guessing ids. Fixed to look
  # up by the actual primary key, scoped to the current tenant.
  def set_template
    @template = HotspotSmsTemplate.find_by(id: params[:id], account_id: @account.id)
    render json: { error: 'Template not found' }, status: :not_found unless @template
  end

  # Adds `group`/`kind` (derived from `category`) so the frontend can keep
  # sorting templates into the Single User / Multi User sections without
  # re-deriving anything from the numeric id.
  def serialize_template(template)
    group, kind = template.category.split('_', 2)
    {
      id: template.id,
      category: template.category,
      group: group,
      kind: kind,
      title: template.title,
      message: template.message,
      active: template.active
    }
  end

  def hotspot_sms_template_params
    params.require(:hotspot_sms_template).permit(:message, :active, :title)
  end
end