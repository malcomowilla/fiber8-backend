class NodesController < ApplicationController
  # before_action :set_node, only: %i[ show edit update destroy ]


set_current_tenant_through_filter

before_action :set_tenant
before_action :update_last_activity


  # GET /nodes or /nodes.json
  def index
    @nodes = Node.all
    render json: @nodes
  end


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
  # GET /nodes/1 or /nodes/1.json
  

  # GET /nodes/new

  # GET /nodes/1/edit
 

  # POST /nodes or /nodes.json
  def create
    @node = Node.new(
      name: params[:name],
      latitude: params[:position][:lat],
      longitude: params[:position][:lng],
      country: params[:country]
    )
    ActivtyLog.create(action: 'create', ip: request.remote_ip,
 description: "Created node #{@node.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)

      if @node.save
        render json: @node, status: :created
      else
        render json: @node.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /nodes/1 or /nodes/1.json
  def update
    @node = Node.find_by(id: params[:id])
      if @node.update(node_params)
        ActivtyLog.create(action: 'update', ip: request.remote_ip,
 description: "Updated node #{@node.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
         render json: @node, status: :ok
      else
         render json: @node.errors, status: :unprocessable_entity 
      
    end
  end

  # DELETE /nodes/1 or /nodes/1.json
  def destroy
    @node = Node.find_by(id: params[:id])
    ActivtyLog.create(action: 'delete', ip: request.remote_ip,
 description: "Deleted node #{@node.name}",
          user_agent: request.user_agent, user: current_user.username || current_user.email,
           date: Time.current)
    @node.destroy!

       head :no_content 
    
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_node
      @node = Node.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def node_params
      params.require(:node).permit(:name, :latitude, :longitude, :country)
    end
end
