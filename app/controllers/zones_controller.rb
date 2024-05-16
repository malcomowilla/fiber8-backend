class ZonesController < ApplicationController

  set_current_tenant_through_filter

  before_action :set_my_tenant
  # before_action :set_zone, only: %i[ show edit update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :zone_not_found_response

  
  
  
    def set_my_tenant
      set_current_tenant(current_user.account)
    end


  # GET /zones or /zones.json
  def index
    @zones = Zone.all
    render json: @zones
  end


  # GET /zones/new
  def create
    @zone = Zone.create(zone_params)

    if @zone
      render json: @zone, status: :created


    else
      render json: {error: 'canot process zone'}, status: :unprocessable_entity
    end
  end

  

  # PATCH/PUT /zones/1 or /zones/1.json
  def update
   found_zone = set_zone
    found_zone.update(updated_params)
    render json: found_zone
 
   

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zone
      @zone = Zone.find_by(id: params[:id])
    end


    def updated_params 
      params.require(:zone).permit(:name, :zone_code)

    end
    # Only allow a list of trusted parameters through.
    def zone_params
      params.require(:zone).permit(:name,:zone_code)
    end



def zone_not_found_response
  render json: { error: "Zone Not Found" }, status: :not_found
end



end
