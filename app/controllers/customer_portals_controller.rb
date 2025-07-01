class CustomerPortalsController < ApplicationController
  before_action :set_customer_portal, only: %i[ show edit update destroy ]


  set_current_tenant_through_filter

  before_action :set_tenant



def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
  
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  # GET /customer_portals or /customer_portals.json
  def index
    @customer_portals = CustomerPortal.all
    render json: @customer_portals
  end


  # POST /customer_portals or /customer_portals.json
  def customer_login
    @customer = Subscriber.find_by(
      ppoe_username: params[:username],
      ppoe_password: params[:password]
    )
        if @customer.nil?
          render json: { error: 'User Not Found' }, status: :not_found and return
        end


       
        if @customer
          # set_current_tenant(@user.account)
          # session[:user_id] = @user.id
          # reset_login_attempts 
          token = generate_token(customer_id: @customer.id)
          cookies.encrypted.signed[:jwt_customer] = { value: token, httponly: true, secure: true,
         sameSite: 'strict'}

render json:@customer,   status: :accepted  

      else
        render json: { error: 'Invalid username or password' }, status: :unauthorized
      end
      end
    
  

  # PATCH/PUT /customer_portals/1 or /customer_portals/1.json
  def update
      if @customer_portal.update(customer_portal_params)
         render :show, status: :ok, location: @customer_portal 
      else
       render json: @customer_portal.errors, status: :unprocessable_entity 
      
    end
  end



  def currently_logged_in_customer
    if  current_customer
        render json: current_customer, status: :accepted
        return
    else
        render json: { error: "Not authorized" }, status: :unauthorized
    end
end

  # DELETE /customer_portals/1 or /customer_portals/1.json
  def customer_logout
  

  cookies.delete(:jwt_customer)
  # head :no_content
  render json: { message: 'Logged out' }, status: :ok
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_customer_portal
      @customer_portal = CustomerPortal.find(params[:id])
    end

def generate_token(payload)
        JWT.encode(payload, ENV['JWT_SECRET'], 'HS256')
      end


    # Only allow a list of trusted parameters through.
    def customer_portal_params
      params.require(:customer_portal).permit(:username, :password,)
    end
end
