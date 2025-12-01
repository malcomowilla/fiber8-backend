class TemporarySessionsController < ApplicationController
  before_action :set_temporary_session, only: %i[ show edit update destroy ]

  # GET /temporary_sessions or /temporary_sessions.json
  def index
    @temporary_sessions = TemporarySession.all
  end

  # GET /temporary_sessions/1 or /temporary_sessions/1.json
  def show
  end

  # GET /temporary_sessions/new
  def new
    @temporary_session = TemporarySession.new
  end

  # GET /temporary_sessions/1/edit
  def edit
  end

  # POST /temporary_sessions or /temporary_sessions.json
  def create
    @temporary_session = TemporarySession.new(temporary_session_params)

    respond_to do |format|
      if @temporary_session.save
        format.html { redirect_to @temporary_session, notice: "Temporary session was successfully created." }
        format.json { render :show, status: :created, location: @temporary_session }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @temporary_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /temporary_sessions/1 or /temporary_sessions/1.json
  def update
    respond_to do |format|
      if @temporary_session.update(temporary_session_params)
        format.html { redirect_to @temporary_session, notice: "Temporary session was successfully updated." }
        format.json { render :show, status: :ok, location: @temporary_session }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @temporary_session.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /temporary_sessions/1 or /temporary_sessions/1.json
  def destroy
    @temporary_session.destroy!

    respond_to do |format|
      format.html { redirect_to temporary_sessions_path, status: :see_other, notice: "Temporary session was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_temporary_session
      @temporary_session = TemporarySession.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def temporary_session_params
      params.require(:temporary_session).permit(:session, :ip, :created_at, :account_id)
    end
end
