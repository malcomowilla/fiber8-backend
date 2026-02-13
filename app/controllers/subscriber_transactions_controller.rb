class SubscriberTransactionsController < ApplicationController

 load_and_authorize_resource 


  set_current_tenant_through_filter
before_action :set_tenant

  before_action :update_last_activity
    before_action :set_time_zone





   def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end




 def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
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









  def index
    @subscriber_transactions = SubscriberTransaction.all
    render json: @subscriber_transactions
  end

  

  # GET /subscriber_transactions/new
  

  # GET /subscriber_transactions/1/edit
  

  # POST /subscriber_transactions or /subscriber_transactions.json
  def create
    @subscriber_transaction = SubscriberTransaction.new(subscriber_transaction_params)

    respond_to do |format|
      if @subscriber_transaction.save
        format.html { redirect_to @subscriber_transaction, notice: "Subscriber transaction was successfully created." }
        format.json { render :show, status: :created, location: @subscriber_transaction }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscriber_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriber_transactions/1 or /subscriber_transactions/1.json
  def update
    respond_to do |format|
      if @subscriber_transaction.update(subscriber_transaction_params)
        format.html { redirect_to @subscriber_transaction, notice: "Subscriber transaction was successfully updated." }
        format.json { render :show, status: :ok, location: @subscriber_transaction }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscriber_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriber_transactions/1 or /subscriber_transactions/1.json
  def destroy
    @subscriber_transaction.destroy!

    respond_to do |format|
      format.html { redirect_to subscriber_transactions_path, status: :see_other, notice: "Subscriber transaction was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscriber_transaction
      @subscriber_transaction = SubscriberTransaction.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscriber_transaction_params
      params.require(:subscriber_transaction).permit(:type, :credit, :debit, :date, :title, :description, :account_id)
    end
end
