class QrCodesController < ApplicationController
 require 'base64'

def make_qr_code
  host = request.headers['X-Subdomain']
  Rails.logger.info "Setting tenant for host qr code: #{host}"
  @current_account = Account.find_by(subdomain: host)

  unless @current_account
    render json: { error: 'Account not found' }, status: :not_found and return
  end

  
qr = RQRCode::QRCode.new("https://#{host}/client-login")
png = qr.as_png(size: 300)

# Convert to base64 for easy display in frontend or API
qr_base64 = Base64.strict_encode64(png.to_s)

  render json: { qr_code_base64: "data:image/png;base64,#{qr_base64}" }, status: :ok
end
end




