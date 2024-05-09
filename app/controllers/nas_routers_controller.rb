class NasRoutersController < ApplicationController
  before_action :set_nas_router, only: %i[ show edit update destroy ]

  # GET /nas_routers or /nas_routers.json
  def index
    @nas_routers = NasRouter.all
  end

  # GET /nas_routers/1 or /nas_routers/1.json
  def show
  end

  # GET /nas_routers/new
  def new
    @nas_router = NasRouter.new
  end

  # GET /nas_routers/1/edit
  def edit
  end

  # POST /nas_routers or /nas_routers.json
  def create
    @nas_router = NasRouter.new(nas_router_params)

      if @nas_router.save
        render json: {message: "Nas router was successfully saved." },status: :created
      else
        render json: {error: 'Error Processing the request' }, status: :unprocessable_entity
      end
    end
  end

  # PATCH/PUT /nas_routers/1 or /nas_routers/1.json
  def update
    respond_to do |format|
      if @nas_router.update(nas_router_params)
        format.html { redirect_to nas_router_url(@nas_router), notice: "Nas router was successfully updated." }
        format.json { render :show, status: :ok, location: @nas_router }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @nas_router.errors, status: :unprocessable_entity }
      end
    end
  

  # DELETE /nas_routers/1 or /nas_routers/1.json
  def destroy
    @nas_router.destroy!

    respond_to do |format|
      format.html { redirect_to nas_routers_url, notice: "Nas router was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_nas_router
      @nas_router = NasRouter.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def nas_router_params
      params.require(:nas_router).permit(:name, :ip_address, :username, :password)
    end
end
