class CollectorWalletController < ApplicationController
  include CollectorAuth

  # POST /api/collector/withdrawals
  def withdraw
    CollectorTransaction.withdraw_all
    render json: { ok: true }, status: :created
  rescue CollectorTransaction::NothingToWithdraw
    render json: { error: "Nothing to withdraw." }, status: :unprocessable_entity
  end
end


