class ReferralEarningsMaturityJob
  include Sidekiq::Job

  def perform
    ReferralEarning.where(status: 'pending')
                   .where('available_at <= ?', Time.current)
                   .find_each { |earning| earning.update!(status: 'available') }
  end
end