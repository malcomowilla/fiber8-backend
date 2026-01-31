class SubscriberWalletBalancesController < ApplicationController



  set_current_tenant_through_filter
before_action :set_tenant

  before_action :update_last_activity
    before_action :set_time_zone



def set_time_zone
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone

end




 def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end



def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end






  # GET /subscriber_wallet_balances or /subscriber_wallet_balances.json
  def index
    @subscriber_wallet_balances = SubscriberWalletBalance.where(subscriber_id: params[:subscriber_id])
    render json: @subscriber_wallet_balances
  end

  # GET /subscriber_wallet_balances/1 or /subscriber_wallet_balances/1.json
  def show
  end

  # GET /subscriber_wallet_balances/new
  def new
    @subscriber_wallet_balance = SubscriberWalletBalance.new
  end

  # GET /subscriber_wallet_balances/1/edit
  def edit
  end

  # POST /subscriber_wallet_balances or /subscriber_wallet_balances.json
  def create
    @subscriber_wallet_balance = SubscriberWalletBalance.first_or_initialize(
      subscriber_id: params[:subscriber_id],
      amount: params[:amount]
    )
    @subscriber_wallet_balance.update(
      subscriber_id: params[:subscriber_id],
      amount: params[:amount]
    )
      if @subscriber_wallet_balance.save
        SubscriberChannel.broadcast_to(@subscriber_wallet_balance.subscriber_id, event: 'wallet_balance_updated', amount: @subscriber_wallet_balance.amount)
        render json: @subscriber_wallet_balance, status: :created
      else
     render json: @subscriber_wallet_balance.errors, status: :unprocessable_entity 
      end
  
  end

  # PATCH/PUT /subscriber_wallet_balances/1 or /subscriber_wallet_balances/1.json
  def update
    respond_to do |format|
      if @subscriber_wallet_balance.update(subscriber_wallet_balance_params)
        format.html { redirect_to @subscriber_wallet_balance, notice: "Subscriber wallet balance was successfully updated." }
        format.json { render :show, status: :ok, location: @subscriber_wallet_balance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscriber_wallet_balance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriber_wallet_balances/1 or /subscriber_wallet_balances/1.json
  def destroy
    @subscriber_wallet_balance.destroy!

    respond_to do |format|
      format.html { redirect_to subscriber_wallet_balances_path, status: :see_other, notice: "Subscriber wallet balance was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscriber_wallet_balance
      @subscriber_wallet_balance = SubscriberWalletBalance.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscriber_wallet_balance_params
      params.require(:subscriber_wallet_balance).permit(:amount, :account_id)
    end
end
