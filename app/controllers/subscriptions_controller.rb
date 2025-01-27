class SubscriptionsController < ApplicationController
  # before_action :set_subscription, only: %i[ show edit update destroy ]

  # GET /subscriptions or /subscriptions.json



before_action :set_current_tenant


  def set_current_tenant
    host = request.headers['X-Subdomain']
    if host.present?
      Rails.logger.info "Setting tenant for host: #{host}"
    
      begin
        # Find or create the account based on the subdomain
        account = Account.find_or_create_by(subdomain: host)
    
        # Ensure the account is valid and has a subdomain
        if account.subdomain.present?
          ActsAsTenant.current_tenant = account
        else
          Rails.logger.error "Invalid account or empty subdomain for host: #{host}"
          # Handle the error case (e.g., raise an exception or return an error response)
        end
      rescue => e
        Rails.logger.error "Error setting tenant for host: #{host}. Error: #{e.message}"
        # Handle the exception (e.g., raise an exception or return an error response)
      end
    
    end

  def index
    @subscriptions = Subscription.all
    render json: @subscriptions
  end


  # POST /subscriptions or /subscriptions.json
  def create
    @subscription = Subscription.first_or_initialize(subscription_params)
    @subscription.update(subscription_params)
      if @subscription.save
         render json: @subscription, status: :created
      else
     render json: @subscription.errors, status: :unprocessable_entity 
      end
    

  end

  
  # # DELETE /subscriptions/1 or /subscriptions/1.json
  # def destroy
  #   @subscription.destroy!

  #   respond_to do |format|
  #     format.html { redirect_to subscriptions_url, notice: "Subscription was successfully destroyed." }
  #     format.json { head :no_content }
  #   end
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscription
      @subscription = Subscription.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscription_params
      params.require(:subscription).permit(:name, :phone, :package, :status, :last_subscribed, :expiry)
    end
end
