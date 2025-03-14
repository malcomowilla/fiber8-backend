class PpPoePlansController < ApplicationController
  before_action :set_pp_poe_plan, only: %i[ show edit update destroy ]

  # GET /pp_poe_plans or /pp_poe_plans.json
  def index
    @pp_poe_plans = PpPoePlan.all
    render json: @pp_poe_plans
  end

  # GET /pp_poe_plans/1 or /pp_poe_plans/1.json
  def show
  end

  # GET /pp_poe_plans/new
  def new
    @pp_poe_plan = PpPoePlan.new
  end

  # GET /pp_poe_plans/1/edit
  def edit
  end

  # POST /pp_poe_plans or /pp_poe_plans.json
  def create
    @pp_poe_plan = PpPoePlan.new(pp_poe_plan_params)

    respond_to do |format|
      if @pp_poe_plan.save
        format.html { redirect_to @pp_poe_plan, notice: "Pp poe plan was successfully created." }
        format.json { render :show, status: :created, location: @pp_poe_plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pp_poe_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pp_poe_plans/1 or /pp_poe_plans/1.json
  def update
    respond_to do |format|
      if @pp_poe_plan.update(pp_poe_plan_params)
        format.html { redirect_to @pp_poe_plan, notice: "Pp poe plan was successfully updated." }
        format.json { render :show, status: :ok, location: @pp_poe_plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pp_poe_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pp_poe_plans/1 or /pp_poe_plans/1.json
  def destroy
    @pp_poe_plan.destroy!

    respond_to do |format|
      format.html { redirect_to pp_poe_plans_path, status: :see_other, notice: "Pp poe plan was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pp_poe_plan
      @pp_poe_plan = PpPoePlan.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pp_poe_plan_params
      params.require(:pp_poe_plan).permit(:maximum_pppoe_subscribers)
    end
end
