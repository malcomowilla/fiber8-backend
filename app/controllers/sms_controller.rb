class SmsController < ApplicationController
  before_action :set_sm, only: %i[ show edit update destroy ]

  # GET /sms or /sms.json
  def index
    @sms = Sm.all
  end

  # GET /sms/1 or /sms/1.json
  def show
  end

  # GET /sms/new
  def new
    @sm = Sm.new
  end

  # GET /sms/1/edit
  def edit
  end


  def get_the_sms_balance

sms_leopard = ActsAsTenant.current_tenant.sms_setting.sms_provider == 'SMS leopard' 


if sms_leopard
  get_balance
end

    # get_balance

  end

  # POST /sms or /sms.json
  def create
    @sm = Sm.new(sm_params)

    respond_to do |format|
      if @sm.save
        format.html { redirect_to sm_url(@sm), notice: "Sm was successfully created." }
        format.json { render :show, status: :created, location: @sm }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sm.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sms/1 or /sms/1.json
  def update
    respond_to do |format|
      if @sm.update(sm_params)
        format.html { redirect_to sm_url(@sm), notice: "Sm was successfully updated." }
        format.json { render :show, status: :ok, location: @sm }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sm.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sms/1 or /sms/1.json
  def destroy
    @sm.destroy!

    respond_to do |format|
      format.html { redirect_to sms_url, notice: "Sm was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.




    def get_balance
      api_key = ENV['SMS_LEOPARD_API_KEY']
      api_secret = ENV['SMS_LEOPARD_API_SECRET']
  
      uri = URI("https://api.smsleopard.com/v1/balance")
      params = {
        username: api_key,
        password: api_secret,
       
      }
      uri.query = URI.encode_www_form(params)
  
      response = Net::HTTP.get_response(uri)
      if response.is_a?(Net::HTTPSuccess)
        puts "Your Balance #{response.body}"
        balance_data = JSON.parse(response.body)
        balance = balance_data['balance']
        render json: {message: "SMS Balance:#{balance}"},status: :ok
      else
        render json: {error: "Error Getting Balance: #{response.body}" }
        puts "Error Getting Balance: #{response.body}"
      end
    end

    def set_sm
      @sm = Sm.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sm_params
      params.require(:sm).permit(:user, :message, :date, :status, :admin_user, :system_user, :account_id)
    end
end
