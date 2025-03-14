class HotspotPlansController < ApplicationController
  before_action :set_hotspot_plan, only: %i[ show edit update destroy ]

  # GET /hotspot_plans or /hotspot_plans.json
  def index
    @hotspot_plans = HotspotPlan.all
    render json: @hotspot_plans
  end

  # GET /hotspot_plans/1 or /hotspot_plans/1.json
  def show
  end

  # GET /hotspot_plans/new
  def new
    @hotspot_plan = HotspotPlan.new
  end

  # GET /hotspot_plans/1/edit
  def edit
  end

  # POST /hotspot_plans or /hotspot_plans.json
  def create
    @hotspot_plan = HotspotPlan.new(hotspot_plan_params)

    respond_to do |format|
      if @hotspot_plan.save
        format.html { redirect_to @hotspot_plan, notice: "Hotspot plan was successfully created." }
        format.json { render :show, status: :created, location: @hotspot_plan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @hotspot_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hotspot_plans/1 or /hotspot_plans/1.json
  def update
    respond_to do |format|
      if @hotspot_plan.update(hotspot_plan_params)
        format.html { redirect_to @hotspot_plan, notice: "Hotspot plan was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_plan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotspot_plans/1 or /hotspot_plans/1.json
  def destroy
    @hotspot_plan.destroy!

    respond_to do |format|
      format.html { redirect_to hotspot_plans_path, status: :see_other, notice: "Hotspot plan was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_plan
      @hotspot_plan = HotspotPlan.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_plan_params
      params.require(:hotspot_plan).permit(:name, :hotspot_subscribers)
    end
end
