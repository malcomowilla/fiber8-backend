class NodesController < ApplicationController
  before_action :set_node, only: %i[ show edit update destroy ]

  # GET /nodes or /nodes.json
  def index
    @nodes = Node.all
    render json: @nodes
  end

  # GET /nodes/1 or /nodes/1.json
  

  # GET /nodes/new

  # GET /nodes/1/edit
 

  # POST /nodes or /nodes.json
  def create
    @node = Node.new(node_params)

      if @node.save
        render json: @node, status: :created
      else
        render json: @node.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /nodes/1 or /nodes/1.json
  def update
    respond_to do |format|
      if @node.update(node_params)
        format.html { redirect_to @node, notice: "Node was successfully updated." }
        format.json { render :show, status: :ok, location: @node }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @node.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /nodes/1 or /nodes/1.json
  def destroy
    @node.destroy!

    respond_to do |format|
      format.html { redirect_to nodes_path, status: :see_other, notice: "Node was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_node
      @node = Node.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def node_params
      params.require(:node).permit(:name, :latitude, :longitude)
    end
end
