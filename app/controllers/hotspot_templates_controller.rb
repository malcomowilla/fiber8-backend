class HotspotTemplatesController < ApplicationController
  # before_action :set_hotspot_template, only: %i[ show edit update destroy ]

load_and_authorize_resource

  set_current_tenant_through_filter
  before_action :set_tenant


  def set_tenant

    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
  
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end



  # GET /hotspot_templates or /hotspot_templates.json
  def index
    @hotspot_templates = HotspotTemplate.all
    render json: @hotspot_templates
  end




  def allow_get_hotspot_templates 
    @hotspot_templates = HotspotTemplate.all
    render json: @hotspot_templates
  end

  # GET /hotspot_templates/1/edit




  # POST /hotspot_templates or /hotspot_templates.json
  def create
    @hotspot_template = HotspotTemplate.first_or_initialize(
name: params[:hotspot_templates][:name],
preview_image: params[:hotspot_templates][:preview_image],
sleekspot: params[:hotspot_templates][:sleekspot],
attractive: params[:hotspot_templates][:attractive],
clean: params[:hotspot_templates][:clean],
flat: params[:hotspot_templates][:flat],
minimal: params[:hotspot_templates][:minimal],
simple: params[:hotspot_templates][:simple],
default_template: params[:hotspot_templates][:default_template],
default: params[:hotspot_templates][:default]
    )
    @hotspot_template.update(
      name: params[:hotspot_templates][:name],
      preview_image: params[:hotspot_templates][:preview_image],
      sleekspot: params[:hotspot_templates][:sleekspot],
      attractive: params[:hotspot_templates][:attractive],
      clean: params[:hotspot_templates][:clean],
      flat: params[:hotspot_templates][:flat],
      minimal: params[:hotspot_templates][:minimal],
      simple: params[:hotspot_templates][:simple],
      default_template: params[:hotspot_templates][:default_template],
      default: params[:hotspot_templates][:default]
    )
      if @hotspot_template.save
         render json:@hotspot_template, status: :created
      else
        render json: @hotspot_template.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /hotspot_templates/1 or /hotspot_templates/1.json
  # def update
  #   respond_to do |format|
  #     if @hotspot_template.update(hotspot_template_params)
  #       format.html { redirect_to @hotspot_template, notice: "Hotspot template was successfully updated." }
  #       format.json { render :show, status: :ok, location: @hotspot_template }
  #     else
  #       format.html { render :edit, status: :unprocessable_entity }
  #       format.json { render json: @hotspot_template.errors, status: :unprocessable_entity }
  #     end
  #   end
  # end

  # DELETE /hotspot_templates/1 or /hotspot_templates/1.json
  def destroy
    @hotspot_template.destroy!

    respond_to do |format|
      format.html { redirect_to hotspot_templates_path, status: :see_other, notice: "Hotspot template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_hotspot_template
      @hotspot_template = HotspotTemplate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def hotspot_template_params
      params.permit(:name,:preview_image, :sleekspot, :attractive, 
      :clean, :default, :flat, :minimal, :simple, :default_template, 
      :default_template)
    end




end
