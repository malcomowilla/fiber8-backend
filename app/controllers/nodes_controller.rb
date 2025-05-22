class NodesController < ApplicationController
  # before_action :set_node, only: %i[ show edit update destroy ]


set_current_tenant_through_filter

before_action :set_tenant


  # GET /nodes or /nodes.json
  def index
    @nodes = Node.all
    render json: @nodes
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
         render json: @node, status: :ok
      else
         render json: @node.errors, status: :unprocessable_entity 
      
    end
  end

  # DELETE /nodes/1 or /nodes/1.json
  def destroy
    @node = Node.find_by(id: params[:id])
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
