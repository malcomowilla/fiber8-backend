class PPoePackagesController < ApplicationController
set_current_tenant_through_filter

# before_action :set_tenant





  require 'net/http'
  require 'uri'
  require 'json'
  # GET /p_poe_packages or /p_poe_packages.json

  # def index
  #   @packages = PPoePackage.all # Convert ActiveRecord objects to hashes

rescue_from ActiveRecord::RecordNotFound, with: :not_found_response
before_action :set_my_tenant

  #     # packages = @packages.map { |package| package.as_json }
  
  #     # # Broadcast the packages to the PpoePackagesChannel
  #     # ActionCable.server.broadcast 'PpoePackagesChannel', packages
      
  # end



  def set_my_tenant
    set_current_tenant(current_user.account)
  end



    def delete
      package = PPoePackage.find_by(id: params[:id])

  if package
    package.destroy
    head :no_content
  else
    render json: { error: "Package not found" }, status: :not_found
  end
    end




  # def show
  #   poe = PPoePackage.find_by(id: params[:id])
  #   render json: poe
  # end

  # GET /p_poe_packages/1 or /p_poe_packages/1.json
  def index

    @p_poe_package = PPoePackage.all
 
    render json: @p_poe_package
    puts  @p_poe_package.as_json
  end

  # POST /p_poe_packages or /p_poe_packages.json
  def create

    # ActsAsTenant.with_tenant(current_user.account) do
    @p_poe_package = PPoePackage.create(p_poe_package_params)

    if  @p_poe_package
      
      render json:  @p_poe_package, status: :created
    # ActionCable.server.broadcast("ppoe_packages_channel", message: 'Package Sucessfully Created' )
  else
  
    render json: {error: 'Unprocessable Entity'}, status: :unprocessable_entity
    # ActionCable.server.broadcast("ppoe_packages_channel", error: 'Unprocessable Entity' )

  end


      # end
      
 
    
#   user1 = 'user1'
#   password = ''
#   name = p_poe_package_params[:name]
#     download_limit = p_poe_package_params[:download_limit]
#     upload_limit = p_poe_package_params[:upload_limit]
#     validity = p_poe_package_params[:validity]
#     price =  p_poe_package_params[:price]
#     tx_rate_limit=  p_poe_package_params[:tx_rate_limit]
#     rx_rate_limit = p_poe_package_params[:rx_rate_limit]
#   upload_burst_limit = p_poe_package_params[:upload_burst_limit]
#   download_burst_limit = p_poe_package_params[:download_burst_limit]
#   request_body1={
#     name: name,
#   validity: validity,
#   price: price
#   }


# uri = URI('http://192.168.88.1/rest/user-manager/profile/add')
# request = Net::HTTP::Post.new(uri)
# request.basic_auth user1, password
# request.body = request_body1.to_json

# request['Content-Type'] = 'application/json'

#   response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#     http.request(request)
#   end

#   if response.is_a?(Net::HTTPSuccess)
#     data = JSON.parse(response.body)
#     puts data
#   else
#     puts "Failed to post name and validty: #{response.code} - #{response.message}"
#   end


#   request_body2 = {
    
#     "download-limit" => download_limit,
#     "upload-limit" => upload_limit,
# "name" => name,
# "rate-limit-rx" => rx_rate_limit,
# "rate-limit-tx" => tx_rate_limit,
# "upload-burst-limit" => upload_burst_limit,
# "download-burst-limit" => download_burst_limit
#   }


# uri = URI('http://192.168.88.1/rest/user-manager/limitation/add')
# request = Net::HTTP::Post.new(uri)
# request.basic_auth user1, password
# request.body = request_body2.to_json

# request['Content-Type'] = 'application/json'

# response = Net::HTTP.start(uri.hostname, uri.port) do |http|
#   http.request(request)
# end

# if response.is_a?(Net::HTTPSuccess)
#   data = JSON.parse(response.body)
#   puts data
# else
#   puts "Failed to post upload and download limit : #{response.code} - #{response.message}"
# end
    






  end

  private
    # Use callbacks to share common setup or constraints between actions.
  

    # Only allow a list of trusted parameters through.
    def p_poe_package_params
      params.require(:p_poe_package).permit(:name, :download_limit, :upload_limit, :price, :validity, :upload_burst_limit,
      :download_burst_limit, :tx_rate_limit, :rx_rate_limit,  :validity_period_units
       )
    end


def not_found_response
  render json: { error: "Package not found" }, status: :not_found
end



end
