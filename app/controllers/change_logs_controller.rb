class ChangeLogsController < ApplicationController
  # before_action :set_change_log, only: %i[ show edit update destroy ]

  # GET /change_logs or /change_logs.json
  def index
    @change_logs = ChangeLog.all
    render json: @change_logs
  end

  # GET /change_logs/1 or /change_logs/1.json
  def show
  end

  # GET /change_logs/new
  def new
    @change_log = ChangeLog.new
  end

  # GET /change_logs/1/edit
  def edit
  end

  # POST /change_logs or /change_logs.json
  def create
    @change_log = ChangeLog.first_or_initialize(change_log_params)
    @change_log.update!(change_log_params)

      if @change_log.save
        render json:  @change_log, status: :created
      else
         render json: @change_log.errors, status: :unprocessable_entity 
      
    end
  end

  # PATCH/PUT /change_logs/1 or /change_logs/1.json
  def update
    respond_to do |format|
      if @change_log.update(change_log_params)
        format.html { redirect_to @change_log, notice: "Change log was successfully updated." }
        format.json { render :show, status: :ok, location: @change_log }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @change_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /change_logs/1 or /change_logs/1.json
  def destroy
    @change_log.destroy!

    respond_to do |format|
      format.html { redirect_to change_logs_path, status: :see_other, notice: "Change log was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_change_log
      @change_log = ChangeLog.find_by(id: params[:id])
    end

    # Only allow a list of trusted parameters through.
    def change_log_params
        params.require(:change_log).permit(:version, :change_title, system_changes: [])

    end
end
