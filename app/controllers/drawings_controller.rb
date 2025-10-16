# app/controllers/drawings_controller.rb
class DrawingsController < ApplicationController
  before_action :set_tenant
  before_action :set_drawing, only: [:show, :update, :destroy]

  # GET /api/drawings
  def index
    @drawings = Drawing.all
    render json: { drawings: @drawings }
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

  # POST /api/drawings
  def create
    @drawing = Drawing.new(drawing_params)
    
    if @drawing.save
      render json: { drawing: @drawing }, status: :created
    else
      render json: { errors: @drawing.errors }, status: :unprocessable_entity
    end
  end

  # PUT /api/drawings/:id
  def update
    @drawing = Drawing.find(params[:id])
    if @drawing.update(drawing_params)
      render json: { drawing: @drawing }
    else
      render json: { errors: @drawing.errors }, status: :unprocessable_entity
    end
  end

  # DELETE /api/drawings/:id
  def destroy
    @drawing = Drawing.find(params[:id])
    @drawing.destroy
    head :no_content
  end

  # DELETE /api/drawings/clear_all
  def clear_all
    @subdomain.drawings.destroy_all
    head :no_content
  end

  private

  def set_subdomain
    @subdomain = Subdomain.find_by(name: request.headers['X-Subdomain'])
    render json: { error: 'Subdomain not found' }, status: :not_found unless @subdomain
  end

  def set_drawing
    @drawing = Drawing.find(params[:id])
  end

  def drawing_params
    params.require(:drawing).permit(
      # :type, :title, :drawing_type,
      # :position, :path, :paths, :center, :bounds, :radius,
      # :stroke_color, :stroke_weight, :fill_color
      # 
      :drawing_type,
    :title,
    position: [:lat, :lng],
    path: {},
    paths: {},
    center: [:lat, :lng],
    bounds: [:north, :south, :east, :west]
    )
  end
end