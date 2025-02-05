class SupportTicketsController < ApplicationController
  before_action :set_support_ticket, only: %i[ show edit update destroy ]

  # GET /support_tickets or /support_tickets.json
  def index
    @support_tickets = SupportTicket.all
  end

  # GET /support_tickets/1 or /support_tickets/1.json
  def show
  end

  # GET /support_tickets/new
  def new
    @support_ticket = SupportTicket.new
  end

  # GET /support_tickets/1/edit
  def edit
  end

  # POST /support_tickets or /support_tickets.json
  def create
    @support_ticket = SupportTicket.new(support_ticket_params)

    respond_to do |format|
      if @support_ticket.save
        format.html { redirect_to support_ticket_url(@support_ticket), notice: "Support ticket was successfully created." }
        format.json { render :show, status: :created, location: @support_ticket }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @support_ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /support_tickets/1 or /support_tickets/1.json
  def update
    respond_to do |format|
      if @support_ticket.update(support_ticket_params)
        format.html { redirect_to support_ticket_url(@support_ticket), notice: "Support ticket was successfully updated." }
        format.json { render :show, status: :ok, location: @support_ticket }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @support_ticket.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /support_tickets/1 or /support_tickets/1.json
  def destroy
    @support_ticket.destroy!

    respond_to do |format|
      format.html { redirect_to support_tickets_url, notice: "Support ticket was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_support_ticket
      @support_ticket = SupportTicket.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def support_ticket_params
      params.require(:support_ticket).permit(:issue_description, :status, :priority, :agent, :ticket_number, :customer, :name, :email, :phone_number, :date_created, :ticket_category, :sequence_number, :date_closed, :agent_review, :agent_response, :agent_response, :account_id, :date_of_creation)
    end
end
