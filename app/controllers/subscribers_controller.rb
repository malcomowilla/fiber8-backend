class SubscribersController < ApplicationController
  # before_action :set_subscriber, only: %i[ show edit update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :subscriber_not_found_response
rescue_from  ActiveRecord::RecordInvalid, with: :subscriber_invalid

set_current_tenant_through_filter

before_action :set_my_tenant

def set_tenant

  host = request.headers['X-Subdomain']
  @account = Account.find_by(subdomain: host)
  ActsAsTenant.current_tenant = @account


  # set_current_tenant(@account)
rescue ActiveRecord::RecordNotFound
  render json: { error: 'Invalid tenant' }, status: :not_found

  
end
  #
  # GET /subscribers or /subscribers.json
  def index
    @subscribers = Subscriber.all
    render json: @subscribers, each_serializer: SubscriberSerializer
  end

  # GET /subscribers/1 or /subscribers/1.json
  def show
  end





  
  # POST /subscribers or /subscribers.json
  def create
    @subscriber = Subscriber.new(subscriber_params)
    if @subscriber.save
      Rails.logger.info "Subscriber saved: #{@subscriber.inspect}"
      @account = Account.find_by(domain: request.domain)
  
      if @account.respond_to?(:prefix_and_digits)
        Rails.logger.info "prefix_and_digits association exists"
        @prefix_and_digit = @account.prefix_and_digits.first
        if @prefix_and_digit.present?
          found_prefix = @prefix_and_digit.prefix
          found_digit = @prefix_and_digit.minimum_digits
        else
          Rails.logger.error "PrefixAndDigit not found for the account"
          render json: { error: "PrefixAndDigit not found for the account" }, status: :unprocessable_entity
          return
        end
      else
        Rails.logger.error "prefix_and_digits association does not exist"
        render json: { error: "Account does not have a 'prefix_and_digits' relationship" }, status: :unprocessable_entity
        return
      end
  
  auto_generated_no = @subscriber.ref_no = "#{found_prefix}#{@subscriber.sequence_number.to_s.rjust(found_digit, '0')}" if found_prefix && found_digit
      if params[:check_update_username] == true
        
        @subscriber.update(ppoe_username: auto_generated_no)
      end
  
      if params[:check_update_password] == true
        @subscriber.update(ppoe_password: auto_generated_no)
      end
  
      @subscriber.update(ref_no: auto_generated_no)
      subscriber_id = fetch_subscriber_id_from_mikrotik(@subscriber.ppoe_username)
      if subscriber_id
        @subscriber.update(mikrotik_user_id: subscriber_id)
        render json: @subscriber, status: :created

      else
        Rails.logger.error 'Failed to fetch subscriber_id from mikrotik'
        render json: { error: 'Failed to create subscriber' }, status: :unprocessable_entity
        return
      end
  
    else
      render json: { error: 'Subscriber Already Created' }, status: :unprocessable_entity
    end
  end
  








def get_general_settings
  
  @account = Account.find_by(domain: request.domain)

  if @account.respond_to?(:prefix_and_digits)
    Rails.logger.info "prefix_and_digits association exists"
    @prefix = @account.prefix_and_digits.all
    # render json: @prefix
    render json: @prefix,  context: {check_update_username: params[:check_update_username], 
    check_update_password: params[:check_update_password] , welcome_back_message: params[:welcome_back_message],
    router_name: params[:router_name]
  }

  # render json: @prefix, status: :created, context: {
  #   check_update_username: ActiveModel::Type::Boolean.new.cast(params[:check_update_username]),
  #   check_update_password: ActiveModel::Type::Boolean.new.cast(params[:check_update_password])
  # }
  else
    Rails.logger.error "prefix_and_digits association does not exist"
    render json: { error: "Account does not have a 'prefix_and_digits' relationship" }, status: :unprocessable_entity
  end
  
end


  def update_general_settings
    @account = Account.find_by(domain: request.domain)
    if @account.respond_to?(:prefix_and_digits)
      Rails.logger.info "prefix_and_digits association exists"
      @prefix = @account.prefix_and_digits.first_or_initialize(prefix: params[:prefix] , minimum_digits: params[:minimum_digits])
      @prefix.update(prefix: params[:prefix] , minimum_digits: params[:minimum_digits])
    @prefix.user = current_user


      if @prefix.save
        
        Rails.logger.info "PrefixAndDigit created successfully: #{@prefix.inspect}"
        render json: @prefix, status: :created, serializer: PrefixDigitsSerializer,context: {check_update_username:
         params[:check_update_username],  welcome_back_message: params[:welcome_back_message],
        check_update_password: params[:check_update_password], router_name: params[:router_name] }
      else
        Rails.logger.error "Failed to create PrefixAndDigit: #{@prefix.errors.full_messages.join(", ")}"
        render json: @prefix.errors, status: :unprocessable_entity
      end
    else
      Rails.logger.error "prefix_and_digits association does not exist"
      render json: { error: "Account does not have a 'prefix_and_digits' relationship" }, status: :unprocessable_entity
    end
    



    # if @account.respond_to?(:subscribers)
    #   Rails.logger.info "subscribers association exists"

    #   if params[:check_update_username] == true && params[:check_update_password] == true

    #     render json: {message: 'settings updated'}, serializer: PrefixDigitsSerializer
    #       end
        
          


    #         else
    #           render json: { error: "Account does not have a 'subscribers' relationship" }, status: :unprocessable_entity

    # end
   
  end


  # def update_prefix_and_minimum_no_digits
  #   update(subscriber_prefix_prefered_no_digits_params)
  # end


  # PATCH/PUT /subscribers/1 or /subscribers/1.json
  def update
    found_subscriber = set_subscriber

    found_subscriber.update(subscriber_params)
    render json: found_subscriber

  end


  

    def fetch_subscriber_id_from_mikrotik(ppoe_username) 

      # name = subscriber_params[:name]
      password = subscriber_params[:ppoe_password]
      router_name = session[:router_name]
    # ppoe_username = subscriber_params[:ppoe_username]
      nas_router = NasRouter.find_by(name: router_name)
    if nas_router
      router_ip_address = nas_router.ip_address
        router_password = nas_router.password
       router_username = nas_router.username
    
    else
    
      puts   Rails.logger.info 'router not found'
    end




    request_body={
      name: ppoe_username,
      password:   password ,
    }


    uri = URI("http://#{router_ip_address}/rest/user-manager/user/add")
    request = Net::HTTP::Post.new(uri)

    request.basic_auth router_username, router_password
    request.body = request_body.to_json
    request['Content-Type'] = 'application/json'



    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      
      data = JSON.parse(response.body)
      return data['ret']


    else
      Rails.logger.info "Failed to  create subscriber: #{response.code} - #{response.message}"
    end


    


  end

  # DELETE /subscribers/1 or /subscribers/1.json
  def delete
  found_subscriber = set_subscriber
  found_subscriber.destroy
  head :no_content
  end

  private




        def subscriber_invalid(invalid)
          render json: {error: invalid.record.errors.full_messages}, status: :unprocessable_entity 
        end

        def subscriber_not_found_response
          render json: { error: "Subscriber Not Found" }, status: :not_found

        end


            def set_subscriber
              @subscriber = Subscriber.find_by(id: params[:id])
            end


            def subscriber_prefix_prefered_no_digits_params
              params.permit(:prefix, :minimum_digits)
              
            end


            def prefix_and_digits_params
              params.require(:prefix_and_digit).permit(:prefix, :minimum_digits)
            end
            # Only allow a list of trusted parameters through.
            def subscriber_params
              params.require(:subscriber).permit(:name, :phone_number, :ppoe_username, :ppoe_password, :email, :ppoe_package,
              :date_registered, :ref_no, :valid_until, :router_name, :package_name, :installation_fee, 
              :subscriber_discount, :second_phone_number)
            end


end
