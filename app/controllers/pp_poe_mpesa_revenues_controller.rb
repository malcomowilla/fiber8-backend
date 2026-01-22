class PpPoeMpesaRevenuesController < ApplicationController
  before_action :set_pp_poe_mpesa_revenue, only: %i[ show edit update destroy ]

  # GET /pp_poe_mpesa_revenues or /pp_poe_mpesa_revenues.json
  def index
    @pp_poe_mpesa_revenues = PpPoeMpesaRevenue.all
  end

  # GET /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def show
  end

  # GET /pp_poe_mpesa_revenues/new
  def new
    @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.new
  end

  # GET /pp_poe_mpesa_revenues/1/edit
  def edit
  end

  # POST /pp_poe_mpesa_revenues or /pp_poe_mpesa_revenues.json
  def create
    @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.new(pp_poe_mpesa_revenue_params)

    respond_to do |format|
      if @pp_poe_mpesa_revenue.save
        format.html { redirect_to @pp_poe_mpesa_revenue, notice: "Pp poe mpesa revenue was successfully created." }
        format.json { render :show, status: :created, location: @pp_poe_mpesa_revenue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pp_poe_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def update
    respond_to do |format|
      if @pp_poe_mpesa_revenue.update(pp_poe_mpesa_revenue_params)
        format.html { redirect_to @pp_poe_mpesa_revenue, notice: "Pp poe mpesa revenue was successfully updated." }
        format.json { render :show, status: :ok, location: @pp_poe_mpesa_revenue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pp_poe_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def destroy
    @pp_poe_mpesa_revenue.destroy!

    respond_to do |format|
      format.html { redirect_to pp_poe_mpesa_revenues_path, status: :see_other, notice: "Pp poe mpesa revenue was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pp_poe_mpesa_revenue
      @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pp_poe_mpesa_revenue_params
      params.require(:pp_poe_mpesa_revenue).permit(:payment_method, :amount, :reference, :time_paid, :account_id, :account_number)
    end
end
