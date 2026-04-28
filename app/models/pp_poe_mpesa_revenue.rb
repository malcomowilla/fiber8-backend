class PpPoeMpesaRevenue < ApplicationRecord
   acts_as_tenant(:account)







  scope :today, -> {
    where(created_at: Time.current.beginning_of_day..Time.current)
  }
  
  scope :this_week, -> {
    where(created_at: Time.current.beginning_of_week..Time.current)
  }
  
  scope :this_month, -> {
    where(created_at: Time.current.beginning_of_month..Time.current)
  }


  scope :for_month, ->(year, month) {
    select { |r| Time.strptime(r.time_paid, "%Y%m%d%H%M%S").year == year &&
                  Time.strptime(r.time_paid, "%Y%m%d%H%M%S").month == month }
  }


  scope :this_year, -> {
    where(created_at: Time.current.beginning_of_year..Time.current)
  }
  
  def self.daily_revenue(date = Date.current)
    where(created_at: date.beginning_of_day..date.end_of_day).sum(:amount)
  end
  
  def self.revenue_by_date_range(start_date, end_date)
    where(created_at: start_date.beginning_of_day..end_date.end_of_day)
      .group_by_day(:created_at)
      .sum(:amount)
  end

end
