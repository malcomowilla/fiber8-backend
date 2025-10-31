class CalendarEventsController < ApplicationController
  # before_action :set_calendar_event, only: %i[ show edit update destroy ]


  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity
  load_and_authorize_resource
# before_action :set_qr_codes






# # application_controller.rb




# def set_qr_codes
      
#     host = request.headers['X-Subdomain']
#     @current_account = Account.find_by(subdomain: host)
  
#       # @current_account = ActsAsTenant.current_tenant
#       qr_codes_dir = Rails.root.join('public', 'qr_codes')
      
#       safe_subdomain = @current_account.subdomain.gsub(/[^\w\-]/, '_')  # Replace invalid characters in the subdomain
#       qr_code_path = qr_codes_dir.join("#{safe_subdomain}_qr_code.png")
    
#       FileUtils.mkdir_p(qr_codes_dir) unless Dir.exist?(qr_codes_dir)
    
#       if File.exist?(qr_code_path)
#         Rails.logger.info "QR code for #{@current_account.subdomain} already exists."
#         @qr_code_url = "/qr_codes/#{safe_subdomain}_qr_code.png"
#       else
#         qr_png = RQRCode::QRCode.new("https://#{request.headers['X-Original-Host']}/client-login", size: 10)
#         png_data = qr_png.as_png(offset: 0, color: '000000', shape_rendering: 'crispEdges', module_size: 10)
    
#         File.open(qr_code_path, 'wb') do |file|
#           file.write(png_data)
#         end
    
#         # Optionally, store the URL for the frontend
#         @qr_code_url = "/qr_codes/#{safe_subdomain}_qr_code.png"
#         Rails.logger.info "QR Code saved to #{qr_code_path}"
#       end
#     end


  # GET /calendar_events or /calendar_events.json
  def index
    @calendar_events = CalendarEvent.all
    render json: @calendar_events
  end


  
  def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end


  # def set_tenant

  #   host = request.headers['X-Subdomain'] 
  #   # Rails.logger.info("Setting tenant for host: #{host}")
  
  #   @account = Account.find_by(subdomain: host)
  #   set_current_tenant(@account)
  
  #   unless @account
  #     render json: { error: 'Invalid tenant' }, status: :not_found
  #   end
    
  # end

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


  # GET /calendar_events/1/edit
  def edit
  end

  # POST /calendar_events or /calendar_events.json
  def create
    @calendar_event = CalendarEvent.new(calendar_event_params)
# current_user if current_user
      if @calendar_event.save
        # FcmNotificationJob.perform_now(current_user.fcm_token)
        #  @fcm_token = current_user.fcm_token

      # start_in_minutes: params[:start_in_minutes],
      # start_in_hours: params[:start_in_hours]
      @fcm_token = current_user.fcm_token if current_user
      calendar_settings = ActsAsTenant.current_tenant.calendar_setting
      in_minutes = calendar_settings.start_in_minutes
      in_hours = calendar_settings.start_in_hours

      # FcmNotificationJob.perform_now(@calendar_event.id, @fcm_token)
      notification_time_minutes = @calendar_event.start.in_time_zone - in_minutes.to_i.minutes
      notification_time_hrs = @calendar_event.start.in_time_zone - in_hours.to_i.hours

ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created calendar event #{@calendar_event.title}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      FcmNotificationJob.set(wait_until:notification_time_hrs).perform_later(@calendar_event.id, @fcm_token)
      FcmNotificationJob.set(wait_until:notification_time_minutes).perform_later(@calendar_event.id, @fcm_token)

render json: @calendar_event, status: :created
      else
       render json: @calendar_event.errors, status: :unprocessable_entity 
      end

    
  end

  # PATCH/PUT /calendar_events/1 or /calendar_events/1.json
  def update
    Rails.logger.info "current_user update event: #{current_user.inspect}"
    @calendar_event = CalendarEvent.find_by(id: params[:id])
      if @calendar_event.update(calendar_event_params)
         @fcm_token = current_user.fcm_token if current_user
      calendar_settings = ActsAsTenant.current_tenant.calendar_setting
      in_minutes = calendar_settings.start_in_minutes
      in_hours = calendar_settings.start_in_hours

      # FcmNotificationJob.perform_now(@calendar_event.id, @fcm_token)
      notification_time_minutes = @calendar_event.start.in_time_zone - in_minutes.to_i.minutes
      notification_time_hrs = @calendar_event.start.in_time_zone - in_hours.to_i.hours

ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated calendar event #{@calendar_event.title}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      FcmNotificationJob.set(wait: 2.minutes).perform_later(@calendar_event.id, @fcm_token)
      # FcmNotificationJob.set(wait_until:notification_time_minutes).perform_later(@calendar_event.id, @fcm_token)

       render json: @calendar_event, status: :ok
      else
         render json: @calendar_event.errors, status: :unprocessable_entity 
      end
  end

  # DELETE /calendar_events/1 or /calendar_events/1.json
  def destroy
    @calendar_event = CalendarEvent.find_by(id: params[:id])
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted calendar event #{@calendar_event.title}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    @calendar_event.destroy

      head :no_content    
  end



  private
    # Use callbacks to share common setup or constraints between actions.
    def set_calendar_event
      @calendar_event = CalendarEvent.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def calendar_event_params
      params.require(:calendar_event).permit(:event_title, :start_date_time,
       :end_date_time, :title, :start, :end, :account_id, 
       :client, :assigned_to, :status, :task_type
       )
    end
end
