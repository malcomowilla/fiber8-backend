class ReferralDisbursementsController < ApplicationController
  def results
    Rails.logger.info "REFERRAL B2C RESULT: #{request.body.read}"
    head :ok
  end

  def timeout
    Rails.logger.info "REFERRAL B2C TIMEOUT: #{request.body.read}"
    head :ok
  end
end