class HotspotMpesaRevenuesController < ApplicationController


  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
    before_action :set_time_zone




  def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"
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





def update_last_activity
if current_user
      current_user.update_column(:last_activity_active, Time.now.strftime('%Y-%m-%d %I:%M:%S %p'))
    end
    
  end



  # GET /hotspot_mpesa_revenues or /hotspot_mpesa_revenues.json
  def index
     host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    # @hotspot_mpesa_revenues = HotspotMpesaRevenue.all
    # render json: @hotspot_mpesa_revenues
    @hotspot_mpesa_revenues = Rails.cache.fetch("hotspot_revenues_index_#{@account.id}", expires_in: 2.seconds) do
  HotspotMpesaRevenue.order(created_at: :desc).to_a
   end

# @hotspot_mpesa_revenues = HotspotMpesaRevenue.all
# HotspotMpesaRevenue.order(created_at: :desc).to_a
    render json: @hotspot_mpesa_revenues
  end






def todays_revenue
  # start_time = Time.current.beginning_of_day
  # end_time = Time.current
  # Query
   today = HotspotMpesaRevenue.today.sum(:amount)
  render json: today
end
 


def this_month_revenue
  # start_time = Time.current.beginning_of_month
  # end_time = Time.current

  # render json: HotspotMpesaRevenue.where(created_at: start_time..end_time).sum(:amount)
  this_month = HotspotMpesaRevenue.this_month.sum(:amount)
  render json: this_month
end



def this_year_revenue
  # start_time = Time.current.beginning_of_month
  # end_time = Time.current + 1.year
  this_year = HotspotMpesaRevenue.this_year.sum(:amount)
  render json: this_year
end



def daily_revenue
      date = params[:date] ? Date.parse(params[:date]) : Date.current
      
      revenue = HotspotMpesaRevenue.daily_revenue(date)
      transactions = HotspotMpesaRevenue.where(created_at: date.beginning_of_day..date.end_of_day)
      
      render json: {
        success: true,
        date: date,
        total_revenue: revenue,
        transaction_count: transactions.count,
        transactions: transactions.as_json(only: [:id, :voucher, :amount, :reference, :time_paid, :created_at])
      }
    end




    
    # GET /api/revenue_summary
    def revenue_summary
      today = HotspotMpesaRevenue.today.sum(:amount)
      this_week = HotspotMpesaRevenue.this_week.sum(:amount)
      this_month = HotspotMpesaRevenue.this_month.sum(:amount)
      all_time = HotspotMpesaRevenue.sum(:amount)
      this_year = HotspotMpesaRevenue.this_year.sum(:amount)
      
      # Last 7 days revenue
      last_7_days = (0..6).map do |i|
        date = i.days.ago.to_date
        revenue = HotspotMpesaRevenue.daily_revenue(date)
        { date: date, revenue: revenue }
      end.reverse
      
      render json: {
        success: true,
        summary: {
          today: today,
          this_week: this_week,
          this_month: this_month,
          all_time: all_time,
          this_year: this_year
        },
        last_7_days: last_7_days,
        currency: 'KES'
      }
    end
    
    # GET /api/revenue_by_date_range?start_date=2024-01-01&end_date=2024-01-31
    def revenue_by_date_range
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      
      revenues = HotspotMpesaRevenue.revenue_by_date_range(start_date, end_date)
      
      render json: {
        success: true,
        start_date: start_date,
        end_date: end_date,
        revenues: revenues,
        total: revenues.values.sum
      }
    end
    




  # POST /hotspot_mpesa_revenues or /hotspot_mpesa_revenues.json
  def create
    @hotspot_mpesa_revenue = HotspotMpesaRevenue.new(hotspot_mpesa_revenue_params)

    respond_to do |format|
      if @hotspot_mpesa_revenue.save
        format.html { redirect_to @hotspot_mpesa_revenue, notice: "Hotspot mpesa revenue was successfully created." }
        format.json { render :show, status: :created, location: @hotspot_mpesa_revenue }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @hotspot_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /hotspot_mpesa_revenues/1 or /hotspot_mpesa_revenues/1.json
  def update
    respond_to do |format|
      if @hotspot_mpesa_revenue.update(hotspot_mpesa_revenue_params)
        format.html { redirect_to @hotspot_mpesa_revenue, notice: "Hotspot mpesa revenue was successfully updated." }
        format.json { render :show, status: :ok, location: @hotspot_mpesa_revenue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @hotspot_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /hotspot_mpesa_revenues/1 or /hotspot_mpesa_revenues/1.json
  def destroy
    @hotspot_mpesa_revenue = HotspotMpesaRevenue.find_by(id: params[:id])
    @hotspot_mpesa_revenue.destroy!
    render json: { message: "Hotspot MPESA revenue deleted successfully" }, status: :ok

  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_mpesa_revenue
      @hotspot_mpesa_revenue = HotspotMpesaRevenue.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_mpesa_revenue_params
      params.require(:hotspot_mpesa_revenue).permit(:voucher, :payment_method, :amount,
       :reference, :time_paid, :account_id)
    end
end


