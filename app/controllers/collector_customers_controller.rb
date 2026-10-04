class CollectorCustomersController < ApplicationController
  include CollectorAuth

  # POST /api/collector/customers
  def create
    customer = CollectorCustomer.new(params.permit(:name, :phone, :unit, :collector_building_id))
    if customer.save
      render json: customer.as_row, status: :created
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/collector/customers/:id/pay   (customer paid for one pack)
  def pay
    customer = CollectorCustomer.find_by(id: params[:id]) # only finds this account's customers
    return render json: { error: "Not found" }, status: :not_found unless customer

    CollectorTransaction.record_payment(customer)
    render json: { ok: true }, status: :created
  end
end