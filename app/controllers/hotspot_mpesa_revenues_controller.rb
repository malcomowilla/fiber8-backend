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
    # EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
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
    #  host = request.headers['X-Subdomain']
    # @account = Account.find_by(subdomain: host)
    # @hotspot_mpesa_revenues = HotspotMpesaRevenue.all
    # render json: @hotspot_mpesa_revenues
  @hotspot_mpesa_revenues = HotspotMpesaRevenue
                  .includes(:hotspot_voucher) 
                  .order(created_at: :desc)
   

# @hotspot_mpesa_revenues = HotspotMpesaRevenue.all
# HotspotMpesaRevenue.order(created_at: :desc).to_a
    render json: @hotspot_mpesa_revenues
  end


  

def peak_hour
  peak = HotspotMpesaRevenue
    .joins(:hotspot_voucher)
    .select(
      "EXTRACT(HOUR FROM hotspot_mpesa_revenues.created_at) AS hour,
       COUNT(*) AS vouchers_sold,
       SUM(hotspot_mpesa_revenues.amount) AS total_revenue"
    )
    .group("hour")
    .order("vouchers_sold DESC")
    .limit(1)
    .first

  if peak
    hour = peak.hour.to_i

    formatted_hour = Time.zone.parse("#{hour}:00").strftime("%I:00 %p")

    render json: {
      title: "Peak Hour",
      time: formatted_hour,               # e.g. "08:00 PM"
      vouchers_sold: peak.vouchers_sold.to_i,
      total_revenue: peak.total_revenue.to_f,
      description: "Most vouchers & revenue"
    }
  else
    render json: { message: "No data found" }, status: :not_found
  end
end








  def best_day_summary
  best_day = HotspotMpesaRevenue
    .joins(:hotspot_voucher)
    .select(
      "DATE(hotspot_mpesa_revenues.created_at) AS day,
       SUM(hotspot_mpesa_revenues.amount) AS total_revenue,
       COUNT(*) AS vouchers_sold"
    )
    .group("day")
    .order("total_revenue DESC")
    .limit(1)
    .first

  if best_day
    render json: {
      title: "Best Day Ever",
      total_revenue: best_day.total_revenue.to_f,
      vouchers_sold: best_day.vouchers_sold.to_i,
      day_name: best_day.day.strftime("%A · %d %b")  # e.g. "Tuesday · 28 Mar"
    }
  else
    render json: { message: "No data found" }, status: :not_found
  end
end




def monthly_revenue_detail
  month_param = params[:month] # e.g. "2026-02"
  year, month = month_param.split('-').map(&:to_i)
  account_id = request.headers['X-Subdomain'].to_i

  total_revenue = HotspotMpesaRevenue
                    .where(account_id: account_id)
                    .select { |r| Time.strptime(r.time_paid, "%Y%m%d%H%M%S").year == year &&
                                  Time.strptime(r.time_paid, "%Y%m%d%H%M%S").month == month }
                    .sum(&:amount)

  render json: { revenue: total_revenue }
end


def most_popular_package
  package = HotspotMpesaRevenue
    .joins(:hotspot_voucher)
    .select(
      "hotspot_vouchers.package AS package,
       COUNT(*) AS vouchers_sold,
       SUM(hotspot_mpesa_revenues.amount) AS total_revenue"
    )
    .group("hotspot_vouchers.package")
    .order("vouchers_sold DESC")
    .limit(1)
    .first

  if package
    render json: {
      package: package.package,
      vouchers_sold: package.vouchers_sold.to_i,
      total_revenue: package.total_revenue.to_f
    }
  else
    render json: { message: "No data found" }, status: :not_found
  end
end









def top_customers
    top_customers = HotspotMpesaRevenue
      .joins(:hotspot_voucher)
      .select(
        "hotspot_vouchers.phone AS phone,
         hotspot_mpesa_revenues.name,
         COUNT(hotspot_mpesa_revenues.id) AS total_purchases,
         SUM(hotspot_mpesa_revenues.amount) AS total_spent,
         MAX(hotspot_mpesa_revenues.created_at) AS last_payment_at,
         ARRAY_AGG(DISTINCT hotspot_vouchers.package) AS packages"
      )
      .group("hotspot_vouchers.phone, hotspot_mpesa_revenues.name")
      .order("total_purchases DESC")

    # render json: top_customers.map { |c|
    #   {
    #     phone: c.phone,
    #     name: c.name,
    #     total_purchases: c.total_purchases.to_i,
    #     total_spent: c.total_spent.to_f,
    #     last_payment_at: c.last_payment_at.strftime("%B %d, %Y at %I:%M %p"),
    #     packages: c.packages
    #   }
    # }
    render json: top_customers.each_with_index.map { |c, index|
  {
    rank: index + 1, # 👈 ranking starts from 1
    phone: c.phone,
    name: c.name,
    purchases: c.total_purchases.to_i,
    spent: c.total_spent.to_f,
    last_payment_at: c.last_payment_at.strftime("%B %d, %Y at %I:%M %p"),
    pkg: c.packages
  }
}
  end


def todays_revenue
  # start_time = Time.current.beginning_of_day
  # end_time = Time.current
  #  host = request.headers['X-Subdomain']
  #   @account = Account.find_by(subdomain: host)
    todays_revenue = HotspotMpesaRevenue.today.sum(:amount)
  
   
  render json: todays_revenue
end
 


def this_month_revenue
  # start_time = Time.current.beginning_of_month
  # end_time = Time.current
#  host = request.headers['X-Subdomain']
#     @account = Account.find_by(subdomain: host)
  # render json: HotspotMpesaRevenue.where(created_at: start_time..end_time).sum(:amount)
    this_month = HotspotMpesaRevenue.this_month.sum(:amount)
    
  render json: this_month
end



def this_year_revenue
  # start_time = Time.current.beginning_of_month
  # end_time = Time.current + 1.year
  # host = request.headers['X-Subdomain']
  #   @account = Account.find_by(subdomain: host)

    # Rails.cache.fetch("this_year_revenue_#{host}", expires_in: 1.day) do
    #   this_year = HotspotMpesaRevenue.this_year.sum(:amount)
    #   render json: this_year
    #   end
    this_year = HotspotMpesaRevenue.this_year.sum(:amount)
     render json: this_year
  
end



def daily_revenue
      host = request.headers['X-Subdomain']
        @account = Account.find_by(subdomain: host)
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
      params.require(:hotspot_mpesa_revenue).permit(:voucher, :payment_method,
       :amount,
       :reference, :time_paid, :account_id)
    end
end


