class EventTitlesController < ApplicationController
  before_action :set_event_title, only: %i[ show edit update destroy ]

  # GET /event_titles or /event_titles.json
  def index
    @event_titles = EventTitle.all
  end

  # GET /event_titles/1 or /event_titles/1.json
  def show
  end

  # GET /event_titles/new
  def new
    @event_title = EventTitle.new
  end

  # GET /event_titles/1/edit
  def edit
  end

  # POST /event_titles or /event_titles.json
  def create
    @event_title = EventTitle.new(event_title_params)

    respond_to do |format|
      if @event_title.save
        format.html { redirect_to @event_title, notice: "Event title was successfully created." }
        format.json { render :show, status: :created, location: @event_title }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event_title.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /event_titles/1 or /event_titles/1.json
  def update
    respond_to do |format|
      if @event_title.update(event_title_params)
        format.html { redirect_to @event_title, notice: "Event title was successfully updated." }
        format.json { render :show, status: :ok, location: @event_title }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @event_title.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /event_titles/1 or /event_titles/1.json
  def destroy
    @event_title.destroy!

    respond_to do |format|
      format.html { redirect_to event_titles_path, status: :see_other, notice: "Event title was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event_title
      @event_title = EventTitle.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_title_params
      params.require(:event_title).permit(:start_date_time, :end_date_time, :title, :start, :end, :account_id)
    end
end
