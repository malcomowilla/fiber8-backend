class CompanySettingsController < ApplicationController
  # before_action :set_company_setting, only: %i[ show edit update destroy ]

load_and_authorize_resource except: [:allow_get_company_settings]

set_current_tenant_through_filter

before_action :set_tenant
before_action :update_last_activity




 def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
  end


def set_tenant

  host = request.headers['X-Subdomain'] 
  # Rails.logger.info("Setting tenant for host: #{host}")

  @account = Account.find_by(subdomain: host)
  set_current_tenant(@account)

  unless @account
    render json: { error: 'Invalid tenant' }, status: :not_found
  end
  
end




  # GET /company_settings or /company_settings.json
  def index
    tunnel_host = fetch_loophole_tunnel_hostname

    # @company_settings = CompanySetting.first
     @account = ActsAsTenant.current_tenant
     @company_settings = @account.company_setting
    # render json: @company_settings
    render json: {
      company_name: @company_settings&.company_name,
      contact_info: @company_settings&.contact_info,
      email_info: @company_settings&.email_info,
      agent_email: @company_settings&.agent_email,
      customer_support_phone_number: @company_settings&.customer_support_phone_number,
      customer_support_email: @company_settings&.customer_support_email,
      # logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo, 
      # host: '8209-102-221-35-92.ngrok-free.app', protocol: 'https', port: nil) : nil


  #     logo_url: @company_settings&.logo&.attached? ? 
  # URI.join("https://#{tunnel_host}", Rails.application.routes.url_helpers.rails_blob_path(@company_settings.logo)).to_s : nil
  # 
  



  logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo,
  host: tunnel_host, protocol: 'https', port: nil) : nil





      # customer_support_phone_number: @company_settings&.customer_support_phone_number,
      # logo_url: @company_settings&.logo&.attached? ? url_for(@company_settings.logo) : nil,
      # logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo, host: '38d6-102-221-35-116.ngrok-free.app',
      
      # protocol: 'https'
      # ) : nil

      }

      




  end

  



  def allow_get_company_settings  
    tunnel_host = fetch_loophole_tunnel_hostname

    # account = Account.find_or_create_by(subdomain: host)
    # ActsAsTenant.current_tenant = account
     # @company_settings = CompanySetting.first
     @account = ActsAsTenant.current_tenant
     @company_settings = @account.company_setting
    # render json: @company_settings
    render json: {
      company_name: @company_settings&.company_name,
      contact_info: @company_settings&.contact_info,
      email_info: @company_settings&.email_info,
      agent_email: @company_settings&.agent_email,
      customer_support_email: @company_settings&.customer_support_email,
      customer_support_phone_number: @company_settings&.customer_support_phone_number,
      # logo_url: @company_settings&.logo&.attached? ? url_for(@company_settings.logo,
      # ) : nil
      # 
      #
  #     logo_url: @company_settings&.logo&.attached? ? 
  # "https://8209-102-221-35-92.ngrok-free.app/rails/active_storage/blobs/#{@company_settings.logo.key}" : nil

  #     logo_url: @company_settings&.logo&.attached? ? 
  # URI.join("https://#{tunnel_host}", Rails.application.routes.url_helpers.rails_blob_path(@company_settings.logo)).to_s : nil

      # logo_url: @company_settings&.logo&.attached? ? "#{Rails.application.routes.default_url_options[:host]}/rails/active_storage/blobs/#{@company_settings.logo.key}" : nil





      logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo,
       host: tunnel_host, protocol: 'https', port: nil,
      ) : nil






      # logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo, host: '38d6-102-221-35-116.ngrok-free.app', protocol: 'https') : nil
      # logo_url: @company_settings&.logo&.attached? ? 
      # rails_blob_url(@company_settings.logo, host: '38d6-102-221-35-116.ngrok-free.app', protocol: 'https', port: nil) 
      # : nil
    
      # logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo, host: '38d6-102-221-35-116.ngrok-free.app',
      
      # protocol: 'https'
      # ) : nil
      }
  end
  

  

  # POST /company_settings or /company_settings.json
  def create
    tunnel_host = fetch_loophole_tunnel_hostname

    
  @company_setting = CompanySetting.first_or_initialize(company_setting_params)
  @company_setting.update!(company_setting_params)
  if @company_setting.save
    ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created company setting #{@company_setting.company_name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    # render json: @company_setting
    render json: {
company_name: @company_setting.company_name,
customer_support_email: @company_setting.customer_support_email,
customer_support_phone_number: @company_setting.customer_support_phone_number,
agent_email: @company_setting.agent_email,
contact_info: @company_setting.contact_info,
email_info: @company_setting.email_info,
# logo_url: @company_setting.logo.attached? ? url_for(@company_setting.logo) : nil
# logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo,
#  host: tunnel_host, protocol: 'https', port: nil) : nil

logo_url: @company_settings&.logo&.attached? ? rails_blob_url(@company_settings.logo,
 host: tunnel_host, protocol: 'https', port: nil) : nil
}
  else
    render json: { errors: @company_setting.errors }, status: :unprocessable_entity

  end
  end



  private
   

  def fetch_loophole_tunnel_hostname
  log_output = `journalctl -u loophole -n 200 --no-pager`.strip
    # output = File.read("/var/log/loophole.log")

  match = log_output.match(%r{https://([a-z0-9\-]+\.loophole\.site)})
  match ? match[1] : nil
end

    # Only allow a list of trusted parameters through.
    def company_setting_params
      params.permit(:company_name, :contact_info,
       :email_info, :logo, :customer_support_phone_number, :agent_email, :customer_support_email)
    end
end
