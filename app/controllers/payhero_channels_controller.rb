class PayheroChannelsController < ApplicationController
  include PaymentGatewayVerifiable

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :set_channel, only: %i[set_default destroy]

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # GET /api/payhero_channels
  def index
    channels = PayheroChannel.where(account_id: @account.id).order(is_default: :desc, created_at: :asc)
    render json: channels.map { |c| serialize(c) }
  end

  # POST /api/payhero_channels
  def create
    type           = params[:channel_type].to_s
    short_code     = params[:short_code].to_s.gsub(/\D/, '')
    account_number = params[:account_number].to_s.strip
    description    = params[:description].to_s.strip

    return fail_with('Invalid channel type') unless PayheroChannel::CHANNEL_TYPES.include?(type)
    return fail_with("Paybill or till number must be 4 to 10 digits (got \"#{params[:short_code]}\")") unless short_code.match?(/\A\d{4,10}\z/)
    
    return fail_with('Enter a name for this channel') if description.blank?
    return fail_with('Enter the account number') if type != 'till' && account_number.blank?

    if PayheroChannel.exists?(account_id: @account.id, short_code: short_code, account_number: account_number)
      return fail_with('That channel is already added')
    end

    result = PayheroService.register_channel(
      channel_type: type, short_code: short_code,
      account_number: account_number, description: description
    )
    return fail_with(result[:error] || 'PayHero rejected this channel') unless result[:success]

    payhero_id = result[:response]['id']
    return fail_with('PayHero did not return a channel id') if payhero_id.blank?

    first_one = !PayheroChannel.where(account_id: @account.id, is_active: true).exists?

    channel = PayheroChannel.create!(
      account_id: @account.id, channel_type: type, short_code: short_code,
      account_number: account_number.presence, description: description,
      payhero_channel_id: payhero_id, is_default: first_one, is_active: true
    )

    render json: serialize(channel), status: :created
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "PayheroChannel save failed after PayHero registered it: #{e.message}"
    fail_with("Channel registered but could not be saved: #{e.message}")
  end

  # PATCH /api/payhero_channels/:id/set_default
  def set_default
    PayheroChannel.transaction do
      PayheroChannel.where(account_id: @account.id).update_all(is_default: false)
      @channel.update!(is_default: true)
    end
    render json: serialize(@channel.reload)
  end

  # DELETE /api/payhero_channels/:id
  # Removes it from this tenant. The docs don't list a delete endpoint, so the
  # registered channel stays in your PayHero account (it just stops being used).
  def destroy
    was_default = @channel.is_default
    @channel.destroy!

    if was_default
      PayheroChannel.where(account_id: @account.id, is_active: true).order(:created_at).first&.update!(is_default: true)
    end

    head :no_content
  end

  private

  def set_channel
    @channel = PayheroChannel.find_by!(id: params[:id], account_id: @account.id)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Channel not found' }, status: :not_found
  end

  def fail_with(message)
    render json: { error: message }, status: :unprocessable_entity
  end

  def serialize(c)
    {
      id: c.id, channel_type: c.channel_type, short_code: c.short_code,
      account_number: c.account_number, description: c.description,
      is_default: c.is_default, is_active: c.is_active
    }
  end
end