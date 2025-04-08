class IpNetworksController < ApplicationController
  before_action :set_ip_network, only: %i[ show edit update destroy ]

  # GET /ip_networks or /ip_networks.json
  def index
    @ip_networks = IpNetwork.all
  end

  # GET /ip_networks/1 or /ip_networks/1.json
  def show
  end

  # GET /ip_networks/new
  def new
    @ip_network = IpNetwork.new
  end

  # GET /ip_networks/1/edit
  def edit
  end

  # POST /ip_networks or /ip_networks.json
  def create
    @ip_network = IpNetwork.new(ip_network_params)

    respond_to do |format|
      if @ip_network.save
        format.html { redirect_to @ip_network, notice: "Ip network was successfully created." }
        format.json { render :show, status: :created, location: @ip_network }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @ip_network.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /ip_networks/1 or /ip_networks/1.json
  def update
    respond_to do |format|
      if @ip_network.update(ip_network_params)
        format.html { redirect_to @ip_network, notice: "Ip network was successfully updated." }
        format.json { render :show, status: :ok, location: @ip_network }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @ip_network.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ip_networks/1 or /ip_networks/1.json
  def destroy
    @ip_network.destroy!

    respond_to do |format|
      format.html { redirect_to ip_networks_path, status: :see_other, notice: "Ip network was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ip_network
      @ip_network = IpNetwork.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ip_network_params
      params.require(:ip_network).permit(:network, :title, :ip_adress, :account_id)
    end
end
