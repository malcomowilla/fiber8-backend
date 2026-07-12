class PopsController < ApplicationController


set_current_tenant_through_filter

before_action :set_tenant





  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  Rails.logger.info "Setting tenant for app#{ActsAsTenant.current_tenant}"
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end







  def index
    render json: Pop.all.map(&:as_map_json)
  end

  def show
    render json: @pop.as_map_json
  end

  def create
    pop = Pop.new(pop_params)
    if pop.save
      render json: pop.as_map_json, status: :created
    else
      render json: { errors: pop.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @pop.update(pop_params)
      render json: @pop.as_map_json
    else
      render json: { errors: @pop.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @pop.destroy
    head :no_content
  end

  private

  def set_pop
    @pop = Pop.find(params[:id])
  end

  def pop_params
    source = params[:pop].present? ? params.require(:pop) : params
    source.permit(:name, :lat, :lng, :address, :status, :description, :routerId).tap do |p|
      p[:router_id] = p.delete(:routerId) if p[:routerId].present?
    end
  end
end