class UserGroupsController < ApplicationController

  load_and_authorize_resource


  set_current_tenant_through_filter

  before_action :set_tenant

  before_action :update_last_activity




     def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
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


  # GET /user_groups or /user_groups.json
  def index
    @user_groups = UserGroup.all
    render json: @user_groups
  end

  # GET /user_groups/1 or /user_groups/1.json


  # POST /user_groups or /user_groups.json
  def create
    @user_group = UserGroup.new(
      name: params[:name],
    )

      if @user_group.save
        ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created user group #{@user_group.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
      render json: @user_group, status: :created
      else
        render json: @user_group.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /user_groups/1 or /user_groups/1.json
  def update
    @user_group = set_user_group
      if @user_group.update(name: params[:name])
        ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated user group #{@user_group.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
         render json: @user_group, status: :ok
      else
         render json: @user_group.errors, status: :unprocessable_entity 
      end
    
  end

  # DELETE /user_groups/1 or /user_groups/1.json
  def destroy

    @user_group = set_user_group
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted user group #{@user_group.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    @user_group.destroy!

     head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user_group
      @user_group = UserGroup.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def user_group_params
      params.permit(:name, :account_id)
    end
end
