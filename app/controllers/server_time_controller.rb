# app/controllers/api/server_time_controller.rb
class ServerTimeController < ApplicationController


  set_current_tenant_through_filter
  before_action :set_tenant




  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  end

  def show
    render json: { time: Time.current.iso8601(3) }
  end
end