class CollectorDashboardController < ApplicationController
  include CollectorAuth

  def show
    render json: {
      buildings: CollectorBuilding.order(:name).map(&:as_row),
      customers: CollectorCustomer.order(:name).map(&:as_row),
      transactions: CollectorTransaction.order(created_at: :desc).limit(200).map(&:as_row),
      balance: CollectorTransaction.balance.to_f
    }
  end
end