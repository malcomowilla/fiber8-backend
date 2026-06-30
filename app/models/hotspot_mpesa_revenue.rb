class HotspotMpesaRevenue < ApplicationRecord


  acts_as_tenant(:account)
 belongs_to :hotspot_voucher, optional: true
 after_commit :clear_cache



 def clear_cache
   Rails.cache.delete("hotspot_revenues_index_#{account.id}")
   Rails.cache.delete("todays_revenue_index_#{account.id}")
   Rails.cache.delete("this_month_revenue_index_#{account.id}")
 end


    scope :today, -> { where(created_at: Time.current.beginning_of_day..Time.current, status: "Completed") }


  scope :yesterday, -> {
  where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day, status: "Completed")
}
  
  scope :this_week, -> {
    where(created_at: Time.current.beginning_of_week..Time.current, status: "Completed")
  }
  
  scope :this_month, -> {
    where(created_at: Time.current.beginning_of_month..Time.current, status: "Completed")
  }


  # scope :for_month, ->(year, month) {
  #   select { |r| Time.strptime(r.time_paid, "%Y%m%d%H%M%S").year == year &&
  #                 Time.strptime(r.time_paid, "%Y%m%d%H%M%S").month == month }
  # }



  scope :for_month, ->(year, month) {
  select do |r|
    next false if r.time_paid.blank?

    paid_at = Time.strptime(r.time_paid, "%Y%m%d%H%M%S")

    paid_at.year == year &&
      paid_at.month == month
  end
}



  scope :this_year, -> {
    where(created_at: Time.current.beginning_of_year..Time.current, status: "Completed")
  }
  
  def self.daily_revenue(date = Date.current)
    where(created_at: date.beginning_of_day..date.end_of_day, status: "Completed").sum(:amount)
  end
  
  def self.revenue_by_date_range(start_date, end_date)
    where(created_at: start_date.beginning_of_day..end_date.end_of_day, status: "Completed")
      .group_by_day(:created_at)
      .sum(:amount)
  end

  
end
