


class ConfirmPaymentController < ApplicationController

   before_action :whitelist_mpesa_ips




def whitelist_mpesa_ips
    allowed_ips = [
      '196.201.214.200',
      '196.201.214.206',
      '196.201.213.114',
      '196.201.214.207',
      '196.201.214.208',
      '196.201.213.44',
      '196.201.212.127',
      '196.201.212.138',
      '196.201.212.129',
      '196.201.212.136',
      '196.201.212.74',
      '196.201.212.69'
    ]

    unless allowed_ips.include?(request.remote_ip)
      Rails.logger.info "Not Authorized Safaricom IP: #{request.remote_ip}"
      render json: { error: 'Not Authorized Safaricom IP' }, status: :not_found
    end
  end







  def validation_url
        Rails.logger.info "===== MPESA VALIDATION ====="

     raw_data = request.body.read

    # Parse JSON if it's JSON-formatted
    data = JSON.parse(raw_data) rescue {}

    Rails.logger.info "M-Pesa Callback Received validation: #{data}"
        Rails.logger.info "=========================== validated"

  end

  def confirmation_url
      Rails.logger.info "===== MPESA CONFIRMATION ====="

     raw_data = request.body.read

    # Parse JSON if it's JSON-formatted
    data = JSON.parse(raw_data) rescue {}

    Rails.logger.info "M-Pesa Callback Received confirmation: #{data}"
        Rails.logger.info "=========================== confirmed"
  end


end