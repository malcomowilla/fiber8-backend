class TemplateLocationsController < ApplicationController



  set_current_tenant_through_filter

  before_action :set_tenant
  load_and_authorize_resource
before_action :update_last_activity
before_action :set_time_zone



def set_time_zone
  Rails.logger.info "Setting time zone"
  Time.zone = GeneralSetting.first&.timezone || Rails.application.config.time_zone
    Rails.logger.info "Setting time zone #{Time.zone}"

end


    def update_last_activity
if current_user
      current_user.update!(last_activity_active:Time.current)
    end
    
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





  # GET /template_locations or /template_locations.json
  def index
    template_locations = TemplateLocation.all
    # render json: @template_locations
    # 
    #
    # plans = PpPoePlan.all

templates = [
    {name: 'sleekspot', template_type: 'Sleekspot Template'},
    {name: 'default_template', template_type: 'Default Template'},
    {name: 'attractive', template_type: 'Attractive Template'},
    {name: 'flat', template_type: 'Flat Design Template'},
    {name: 'minimal', template_type: 'Minimal Template'},
    {name: 'simple', template_type: 'Simple Template'},
    {name: 'clean', template_type: 'Clean Template'},
    {name: 'pepea', template_type: 'Pepea Template'},
    {name: 'premium', template_type: 'Premium Template'}
  ]

  if template_locations.empty?
    each_template = templates.each do |template|
        TemplateLocation.create(
          name: template[:name],
          template_type: template[:template_type],
        )
      end
    template_locations = each_template 
  end

  render json: template_locations, each_serializer: TemplateLocationSerializer
  end

  # GET /template_locations/1 or /template_locations/1.json
  def show
  end

  # GET /template_locations/new
  def new
    @template_location = TemplateLocation.new
  end

  # GET /template_locations/1/edit
  def edit
  end

  # POST /template_locations or /template_locations.json
  def create
    @template_location = TemplateLocation.new(template_location_params)

    respond_to do |format|
      if @template_location.save
        format.html { redirect_to @template_location, notice: "Template location was successfully created." }
        format.json { render :show, status: :created, location: @template_location }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @template_location.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /template_locations/1 or /template_locations/1.json
  def update
    @template_location = TemplateLocation.find_by(id: params[:id])
      if @template_location.update(location: params[:selected_locations])
         render json: @template_location, status: :ok
      else
         render json: @template_location.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /template_locations/1 or /template_locations/1.json
  def destroy
    @template_location.destroy!

      head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_template_location
      @template_location = TemplateLocation.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def template_location_params
      params.require(:template_location).permit(:name, :type, :location, :account_id)
    end
end
