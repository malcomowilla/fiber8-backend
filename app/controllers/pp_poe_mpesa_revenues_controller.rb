class PpPoeMpesaRevenuesController < ApplicationController

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  before_action :set_time_zone



 def set_time_zone
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone

end




  def update_last_activity
    current_user&.update!(last_activity_active: Time.current)
  end

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by!(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end



  # GET /pp_poe_mpesa_revenues or /pp_poe_mpesa_revenues.json
  def index
    @pp_poe_mpesa_revenues = PpPoeMpesaRevenue.all
    # render json: @pp_poe_mpesa_revenues
    
  #     @pp_poe_mpesa_revenues = Rails.cache.fetch("pp_poe_mpesa_revenues_index", expires_in: 2.seconds) do
  #   PpPoeMpesaRevenue.order(created_at: :desc).to_a
  # end
    
    render json: @pp_poe_mpesa_revenues
  end

  






def monthly_revenue_detail
  month_param = params[:month] # e.g. "2026-02"
year, month = month_param.split('-').map(&:to_i)

# Build start and end of month
start_time = Time.new(year, month, 1)
end_time   = start_time.end_of_month

total_revenue = PpPoeMpesaRevenue
                  .where(created_at: start_time..end_time)
                  .sum(:amount)

render json: { revenue: total_revenue }
end


def most_popular_package
  package = PpPoeMpesaRevenuE
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




def last_three_months_revenue
  now = Time.current

  months = (0..2).map do |i|
    date = now - i.months
    start_time = date.beginning_of_month
    end_time   = date.end_of_month

    total = PpPoeMpesaRevenue
              .where(created_at: start_time..end_time)
              .sum(:amount)

    {
      month: date.strftime("%b"),      # Apr
      label: date.strftime("%B %Y"),   # April 2026
      total: total
    }
  end.reverse

  render json: {
    monthly: months.index_by { |m| m[:month] }
                    .transform_values { |m| m[:total] }
  }
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
    todays_revenue = PpPoeMpesaRevenueue.today.sum(:amount)
  
   
  render json: todays_revenue
end
 


def this_month_revenue
  # start_time = Time.current.beginning_of_month
  # end_time = Time.current
#  host = request.headers['X-Subdomain']
#     @account = Account.find_by(subdomain: host)
  # render json: HotspotMpesaRevenue.where(created_at: start_time..end_time).sum(:amount)
    this_month = PpPoeMpesaRevenueue.this_month.sum(:amount)
    
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
    this_year = PpPoeMpesaRevenueue.this_year.sum(:amount)
     render json: this_year
  
end



def daily_revenue
      host = request.headers['X-Subdomain']
        @account = Account.find_by(subdomain: host)
      date = params[:date] ? Date.parse(params[:date]) : Date.current
      
      revenue = PpPoeMpesaRevenueue.daily_revenue(date)
      transactions = PpPoeMpesaRevenueue.where(created_at: date.beginning_of_day..date.end_of_day)
      
      render json: {
        success: true,
        date: date,
        total_revenue: revenue,
        transaction_count: transactions.count,
        transactions: transactions.as_json(only: [:id, :voucher, :amount, :reference, :time_paid, :created_at])
      }
    end






def this_week_revenue
  # start_time = Time.current.beginning_of_week
  # end_time = Time.current
  
  # render json: HotspotMpesaRevenue.where(created_at: start_time..end_time).sum(:amount)

start_time = [
  Time.zone.now.beginning_of_week,
  Time.zone.now.beginning_of_month
].max

render json: PpPoeMpesaRevenue.where(created_at: start_time..Time.zone.now).sum(:amount)



end



    
    # GET /api/revenue_summary
    def revenue_summary
      today =PpPoeMpesaRevenue.today.sum(:amount)
      this_week =PpPoeMpesaRevenue.this_week.sum(:amount)
      this_month = PpPoeMpesaRevenue.this_month.sum(:amount)
      all_time = PpPoeMpesaRevenue.sum(:amount)
      this_year = PpPoeMpesaRevenue.this_year.sum(:amount)






        now = Time.current

  months = (0..2).map do |i|
    date = now - i.months
    start_time = date.beginning_of_month
    end_time   = date.end_of_month

    total = PpPoeMpesaRevenue
              .where(created_at: start_time..end_time)
              .sum(:amount)

    {
      month: date.strftime("%b"),      # Apr
      label: date.strftime("%B %Y"),   # April 2026
      total: total
    }
  end.reverse





      
      # Last 7 days revenue
      last_7_days = (0..6).map do |i|
        date = i.days.ago.to_date
        revenue = PpPoeMpesaRevenue.daily_revenue(date)
        { date: date, revenue: revenue }
      end.reverse
      
      render json: {
        success: true,
          monthly: months.index_by { |m| m[:month] }
                    .transform_values { |m| m[:total] },
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
      revenues =  PpPoeMpesaRevenue.revenue_by_date_range(start_date, end_date)
     
       
      
      render json: {
        success: true,
        start_date: start_date,
        end_date: end_date,
        revenues: revenues,
        total: revenues.values.sum
      }
    end
    





  # POST /pp_poe_mpesa_revenues or /pp_poe_mpesa_revenues.json
  def create
    @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.new(

amount: params[:amount],
payment_method: params[:payment_method],
time_paid:  Time.current,
reference: params[:reference],
 customer_name: params[:customer],
    )

      if @pp_poe_mpesa_revenue.save
        render json: @pp_poe_mpesa_revenue, status: :created
      else
         render json: @pp_poe_mpesa_revenue.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def update
    respond_to do |format|
      if @pp_poe_mpesa_revenue.update(pp_poe_mpesa_revenue_params)
        format.html { redirect_to @pp_poe_mpesa_revenue, notice: "Pp poe mpesa revenue was successfully updated." }
        format.json { render :show, status: :ok, location: @pp_poe_mpesa_revenue }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pp_poe_mpesa_revenue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pp_poe_mpesa_revenues/1 or /pp_poe_mpesa_revenues/1.json
  def destroy
    @pp_poe_mpesa_revenue = set_pp_poe_mpesa_revenue
    @pp_poe_mpesa_revenue.destroy!

       head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pp_poe_mpesa_revenue
      @pp_poe_mpesa_revenue = PpPoeMpesaRevenue.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pp_poe_mpesa_revenue_params
      params.require(:pp_poe_mpesa_revenue).permit(:payment_method, :amount,
       :reference, :time_paid, :account_id, :account_number,
       :payment_type
       )
    end
end
