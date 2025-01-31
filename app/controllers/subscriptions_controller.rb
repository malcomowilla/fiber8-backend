class SubscriptionsController < ApplicationController
  # before_action :set_subscription, only: %i[ show edit update destroy ]

  # GET /subscriptions or /subscriptions.json

# set_current_tenant_through_filter

# before_action :set_current_tenant


  
    
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
