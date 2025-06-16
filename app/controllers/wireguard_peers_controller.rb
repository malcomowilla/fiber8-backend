class WireguardPeersController < ApplicationController
  before_action :set_wireguard_peer, only: %i[ show edit update destroy ]

  # GET /wireguard_peers or /wireguard_peers.json
  def index
    @wireguard_peers = WireguardPeer.all
  end

  # GET /wireguard_peers/1 or /wireguard_peers/1.json
  def show
  end

  # GET /wireguard_peers/new
  def new
    @wireguard_peer = WireguardPeer.new
  end

  # GET /wireguard_peers/1/edit
  def edit
  end

  # POST /wireguard_peers or /wireguard_peers.json
  def create
    @wireguard_peer = WireguardPeer.new(wireguard_peer_params)

    respond_to do |format|
      if @wireguard_peer.save
        format.html { redirect_to @wireguard_peer, notice: "Wireguard peer was successfully created." }
        format.json { render :show, status: :created, location: @wireguard_peer }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @wireguard_peer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /wireguard_peers/1 or /wireguard_peers/1.json
  def update
    respond_to do |format|
      if @wireguard_peer.update(wireguard_peer_params)
        format.html { redirect_to @wireguard_peer, notice: "Wireguard peer was successfully updated." }
        format.json { render :show, status: :ok, location: @wireguard_peer }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @wireguard_peer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /wireguard_peers/1 or /wireguard_peers/1.json
  def destroy
    @wireguard_peer.destroy!

    respond_to do |format|
      format.html { redirect_to wireguard_peers_path, status: :see_other, notice: "Wireguard peer was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_wireguard_peer
      @wireguard_peer = WireguardPeer.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def wireguard_peer_params
      params.require(:wireguard_peer).permit(:public_key, :allowed_ips, :persistent_keepalive)
    end
end
