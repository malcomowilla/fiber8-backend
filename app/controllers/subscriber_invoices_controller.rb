class SubscriberInvoicesController < ApplicationController
  before_action :set_subscriber_invoice, only: %i[ show edit update destroy ]



  set_current_tenant_through_filter
before_action :set_tenant
before_action :update_last_activity, only: [:index]

before_action :set_time_zone


def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end



  def get_subscriber_details_by_invoice_id
    shortcode = ActsAsTenant.current_tenant&.hotspot_mpesa_setting.short_code
    subscriber_id = SubscriberInvoice.find_by(id: params[:invoice_id]).subscriber_id
    @subscriber = Subscriber.find_by(id: subscriber_id)
    render json: {subscriber: @subscriber, shortcode: shortcode}
  end

def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end

  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


  # GET /subscriber_invoices or /subscriber_invoices.json
  def index
    @subscriber_invoices = SubscriberInvoice.where(subscriber_id: params[:id])
    render json: @subscriber_invoices
  end

  # GET /subscriber_invoices/1 or /subscriber_invoices/1.json
  def show
  end
  

  # GET /subscriber_invoices/new
  def new
    @subscriber_invoice = SubscriberInvoice.new
  end

  # GET /subscriber_invoices/1/edit
  def edit
  end

  # POST /subscriber_invoices or /subscriber_invoices.json
  def create
    @subscriber_invoice = SubscriberInvoice.new(subscriber_invoice_params)

    respond_to do |format|
      if @subscriber_invoice.save
        format.html { redirect_to @subscriber_invoice, notice: "Subscriber invoice was successfully created." }
        format.json { render :show, status: :created, location: @subscriber_invoice }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subscriber_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subscriber_invoices/1 or /subscriber_invoices/1.json
  def update
    respond_to do |format|
      if @subscriber_invoice.update(subscriber_invoice_params)
        format.html { redirect_to @subscriber_invoice, notice: "Subscriber invoice was successfully updated." }
        format.json { render :show, status: :ok, location: @subscriber_invoice }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subscriber_invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subscriber_invoices/1 or /subscriber_invoices/1.json
  def destroy
    @subscriber_invoice.destroy!

    respond_to do |format|
      format.html { redirect_to subscriber_invoices_path, status: :see_other, notice: "Subscriber invoice was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subscriber_invoice
      @subscriber_invoice = SubscriberInvoice.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def subscriber_invoice_params
      params.require(:subscriber_invoice).permit(:item, :due_date,
       :invoice_date, :invoice_number, :amount, :status, :description,
        :quantity, :account_id)
    end
end
