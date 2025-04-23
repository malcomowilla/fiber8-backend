class SubscriptionsController < ApplicationController
  # before_action :set_subscription, only: %i[ show edit update destroy ]

  # GET /subscriptions or /subscriptions.json

set_current_tenant_through_filter

before_action :set_current_tenant

load_and_authorize_resource

  
    
def set_current_tenant

  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
   @current_account=ActsAsTenant.current_tenant 
  EmailConfiguration.configure(@current_account, ENV['SYSTEM_ADMIN_EMAIL'])

  # set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  
end


  def index
    @subscriptions = Subscription.all
    render json: @subscriptions
  end





  def get_ips
    # Step 1: Get the network details
    network = IpNetwork.find_by(title: params[:network_name])
  
    if network.nil?
      render json: { error: "Network not found" }, status: 404 and return
    end
  
    # Step 2: Parse the network and generate the range
    cidr = "#{network.network}/#{network.subnet_mask}"
    network_range = IPAddr.new(cidr).to_range.to_a
  
    # Step 3: Filter out reserved IPs
    reserved_ips = [
      network_range.first,  # Network address (.0)
      network_range.last,   # Broadcast address (.255)
      IPAddr.new(network_range.first.to_i + 1, Socket::AF_INET)  # Typically .1 (gateway)
    ]
  
    available_ips = network_range - reserved_ips
  
    # Step 4: Exclude already used IPs
    used_ips = Subscription.pluck(:ip_address).compact.map { |ip| IPAddr.new(ip) }
    available_ips -= used_ips
  
    # Step 5: Select a small, unique set of IPs (e.g., 5 IPs)
    limited_ips = available_ips.sample(5) # You can change 5 to whatever small number you want
  
    if limited_ips.empty?
      render json: { error: "No available IPs in the network" }, status: 404 and return
    end
  
    # Step 6: Return the selected IPs
    render json: limited_ips.map(&:to_s)
  end
  

  # POST /subscriptions or /subscriptions.json
  def create

    @subscription = Subscription.create(
      subscription_params
    )
    create_pppoe_credentials_radius(@subscription.pppoe_password, @subscription.pppoe_username, @subscription.package)
    calculate_expiration(@subscription)
      if @subscription.save
         render json: @subscription, status: :created
      else
     render json: @subscription.errors, status: :unprocessable_entity 
      end
    

  end

  
  # DELETE /subscriptions/1 or /subscriptions/1.json
  def destroy
    @subscription = set_subscription
  
    @subscription.destroy!

       head :no_content 
    
  end




  def update
    @subscription = set_subscription
    if @subscription.update(subscription_params)
      calculate_expiration(@subscription)
      render json: @subscription, status: :ok
    else
      render json: @subscription.errors, status: :unprocessable_entity
    end
  end
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find_by(id: params[:id])
    end




    def create_pppoe_credentials_radius(pppoe_password, pppoe_username, package)
  
  
      # hotspot_package = "hotspot_#{package.parameterize(separator: '_')}"
       pppoe_package = "pppoe_#{package.parameterize(separator: '_')}"

      
      RadCheck.create(username: pppoe_username, radiusattribute: 'Cleartext-Password', op: ':=', value: pppoe_password)  
      RadUserGroup.create(username: pppoe_username, groupname:pppoe_package, priority: 1) 
      
      validity_period_units = Package.find_by(name: package).validity_period_units
      validity = Package.find_by(name: package).validity
      
      
      
      expiration_time = case validity_period_units
      when 'days' then Time.current + validity.days
      when 'hours' then Time.current + validity.hours
      when 'minutes' then Time.current + validity.minutes
      end&.strftime("%d %b %Y %H:%M:%S")
      
      if expiration_time
        rad_check = RadGroupCheck.find_or_initialize_by(groupname: pppoe_username, radiusattribute: 'Expiration')
        rad_check.update!(op: ':=', value: expiration_time)
      end
        
      
      
      
      end




    
    def calculate_expiration(subscription)
      return nil unless subscription.validity.present? && subscription.validity_period_units.present?
    
      validity = subscription.validity.to_i
    
      # Calculate expiration time
      expiration_time = case subscription.validity_period_units.downcase
                        when 'days'
                          Time.current + validity.days
                        when 'hours'
                          Time.current + validity.hours
                        when 'minutes'
                          Time.current + validity.minutes
                        else
                          nil
                        end
    
      # If expiration was calculated, update the subscription
      if expiration_time
        subscription.update(expiry: expiration_time)
        formatted_expiry = expiration_time.strftime("%B %d, %Y at %I:%M %p")
      else
        formatted_expiry = "unknown"
      end
    
      # Return formatted expiry
      {
        expiry: formatted_expiry
      }
    end
    






    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:name, :phone_number, :package, :status, 
      :last_subscribed, :expiry, :ip_address,
       :ppoe_username, :ppoe_password, :type, :network_name, :mac_address, :validity_period_units, :validity)
    end

   

end
