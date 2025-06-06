class ZonesController < ApplicationController

  # set_current_tenant_through_filter

  # before_action :set_my_tenant
    # before_save :zone_code
  # before_action :set_zone, only: %i[ show edit update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :zone_not_found_response

  
  
  
    # def set_my_tenant
    #   set_current_tenant(current_user.account)
    # end


  # GET /zones or /zones.json
  def index
    @zones = Zone.all
    render json: @zones
  end


  # GET /zones/new
  def create
    @zone = Zone.create(zone_params)
@zone.zone_code =  SecureRandom.alphanumeric(6).upcase 

    if @zone
      render json: @zone, status: :ok,  serializer:  ZoneSerializer


    else
      render json: {error: 'cannot create zone'}, status: :unprocessable_entity
    end
  end

  

  # PATCH/PUT /zones/1 or /zones/1.json
  def update
   found_zone = set_zone
    found_zone.update(updated_params)
    render json: found_zone
 
   

  end



  def delete
    found_zone = set_zone
    found_zone.destroy
    head :no_content

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


def zone_code
  self.zone_code = SecureRandom.alphanumeric(6) 
  

end

end
