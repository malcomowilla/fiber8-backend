# app/controllers/payment_and_connected_status_controller.rb

class PaymentAndConnectedStatusController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_tenant

  # ═══════════════════════════════════════════════════════════════
  # POST /api/payment_and_conected_status
  # Check payment status + device connected status
  # ═══════════════════════════════════════════════════════════════

  def check_status
    # Get device info
    mac_address = params[:mac_address]
    ip_address = params[:ip_address]
    session_id = params[:session_id]

    # Validate required params
    unless mac_address && ip_address
      return render json: { error: 'MAC and IP address required' }, status: :bad_request
    end

    begin
      # ✅ 1. Check Payment Status
      payment_status = check_payment_status(mac_address, session_id)

      # ✅ 2. Check Device Connection Status
      connection_status = check_device_connection(mac_address, ip_address)

      # ✅ 3. Check for Active Subscription
      subscription_status = check_active_subscription(mac_address)

      render json: {
        status: 'success',
        payment: payment_status,
        connection: connection_status,
        subscription: subscription_status,
        device: {
          mac_address: mac_address,
          ip_address: ip_address
        }
      }
    rescue StandardError => e
      Rails.logger.error "Error checking status: #{e.message}"
      render json: { error: 'Failed to check status' }, status: :internal_server_error
    end
  end

  private

  def set_tenant
    subdomain = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: subdomain)
    ActsAsTenant.current_tenant = @account
  rescue
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  # ═══════════════════════════════════════════════════════════════
  # Check if payment was processed successfully
  # ═══════════════════════════════════════════════════════════════

  def check_payment_status(mac_address, session_id)
    # Look for recent M-Pesa payments
    payment = MpesaPayment.where(
      device_mac: mac_address
    ).where('created_at > ?', 30.minutes.ago).first

    if payment
      {
        status: payment.payment_status,
        amount: payment.amount,
        reference: payment.transaction_id,
        timestamp: payment.created_at,
        paid: payment.payment_status == 'completed'
      }
    else
      {
        status: 'pending',
        paid: false,
        message: 'No payment found'
      }
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # Check device connection status (DHCP, firewall, etc)
  # ═══════════════════════════════════════════════════════════════

  def check_device_connection(mac_address, ip_address)
    # Check if device is bound to IP
    ip_binding = IpBinding.find_by(
      mac_address: mac_address,
      ip_address: ip_address
    )

    if ip_binding&.active?
      {
        connected: true,
        status: 'active',
        mac_address: mac_address,
        ip_address: ip_address,
        bound_at: ip_binding.created_at,
        expires_at: ip_binding.expires_at
      }
    else
      {
        connected: false,
        status: 'not_bound',
        message: 'Device not registered on network'
      }
    end
  end

  # ═══════════════════════════════════════════════════════════════
  # Check if device has active subscription/package
  # ═══════════════════════════════════════════════════════════════

  def check_active_subscription(mac_address)
    # Look for active hotspot subscription
    hotspot_sub = HotspotSubscription.joins(:hotspot_session)
      .where('hotspot_sessions.device_mac' => mac_address)
      .where('hotspot_subscriptions.status' => 'active')
      .where('hotspot_subscriptions.expires_at > ?', Time.current)
      .first

    if hotspot_sub
      {
        has_subscription: true,
        type: 'hotspot',
        package: hotspot_sub.hotspot_package&.name,
        expires_at: hotspot_sub.expires_at,
        data_balance: hotspot_sub.remaining_data,
        status: 'active'
      }
    else
      # Check for TV subscription
      tv_sub = TvSubscription.joins(:device)
        .where('devices.mac_address' => mac_address)
        .where('tv_subscriptions.status' => 'active')
        .where('tv_subscriptions.expires_at > ?', Time.current)
        .first

      if tv_sub
        {
          has_subscription: true,
          type: 'tv',
          plan: tv_sub.tv_plan&.name,
          expires_at: tv_sub.expires_at,
          status: 'active'
        }
      else
        {
          has_subscription: false,
          message: 'No active subscription found'
        }
      end
    end
  end
end