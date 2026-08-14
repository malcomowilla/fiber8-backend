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

    render json: { templates: existing.values.sort_by { |t| HotspotSmsTemplate::CATEGORIES.index(t.category) } }
  end

  # PATCH /api/hotspot_sms_templates/:id
  def update
    if @template.update(hotspot_sms_template_params)
      render json: { template: @template }, status: :ok
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

  # def set_template
  #   @template = HotspotSmsTemplate.find_by(id: params[:id], account_id: @account.id)
  #   render json: { error: 'Template not found' }, status: :not_found unless @template
  # end


  def set_template
  @template = HotspotSmsTemplate.find_by(
    category: params[:id].tr('-', '_'),
    # account_id: @account.id
  )

  render json: { error: 'Template not found' }, status: :not_found unless @template
end



  def hotspot_sms_template_params
    params.require(:hotspot_sms_template).permit(:message, :active, :title)
  end
end