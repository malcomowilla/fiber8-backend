class SmsTemplatesController < ApplicationController
  before_action :set_sms_template, only: %i[ show edit update destroy ]

  # GET /sms_templates or /sms_templates.json
  def index
    @sms_templates = SmsTemplate.all
    render jspn: @sms_templates
  end

  # GET /sms_templates/1 or /sms_templates/1.json
  def show
  end

  # GET /sms_templates/new
  def new
    @sms_template = SmsTemplate.new
  end

  # GET /sms_templates/1/edit
  def edit
  end

  # POST /sms_templates or /sms_templates.json
  def create
    @sms_template = SmsTemplate.first_or_initialize
    @sms_template.update(
      @sms_template.send_voucher_template = sms_template_params[:send_voucher_template],
      @sms_template.voucher_template = sms_template_params[:voucher_template]
    )
      @sms_template.send_voucher_template = sms_template_params[:send_voucher_template]
      @sms_template.voucher_template = sms_template_params[:voucher_template]

      if @sms_template.save
        render json: @sms_template, status: :created
      else
         render json: @sms_template.errors, status: :unprocessable_entity 
      end
    
  end

  # PATCH/PUT /sms_templates/1 or /sms_templates/1.json
  def update
    respond_to do |format|
      if @sms_template.update(sms_template_params)
        format.html { redirect_to @sms_template, notice: "Sms template was successfully updated." }
        format.json { render :show, status: :ok, location: @sms_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sms_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sms_templates/1 or /sms_templates/1.json
  def destroy
    @sms_template.destroy!

    respond_to do |format|
      format.html { redirect_to sms_templates_path, status: :see_other, notice: "Sms template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sms_template
      @sms_template = SmsTemplate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sms_template_params
      params.require(:sms_template).permit(:send_voucher_template, :voucher_template, :account_id)
    end
end
