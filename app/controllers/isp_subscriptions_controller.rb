class IspSubscriptionsController < ApplicationController
  before_action :set_isp_subscription, only: %i[ show edit update destroy ]

  # GET /isp_subscriptions or /isp_subscriptions.json
  def index
    @isp_subscriptions = IspSubscription.all
  end

  # GET /isp_subscriptions/1 or /isp_subscriptions/1.json
  def show
  end

  # GET /isp_subscriptions/new
  def new
    @isp_subscription = IspSubscription.new
  end

  # GET /isp_subscriptions/1/edit
  def edit
  end

  # POST /isp_subscriptions or /isp_subscriptions.json
  def create
    @isp_subscription = IspSubscription.new(isp_subscription_params)

    respond_to do |format|
      if @isp_subscription.save
        format.html { redirect_to @isp_subscription, notice: "Isp subscription was successfully created." }
        format.json { render :show, status: :created, location: @isp_subscription }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @isp_subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /isp_subscriptions/1 or /isp_subscriptions/1.json
  def update
    respond_to do |format|
      if @isp_subscription.update(isp_subscription_params)
        format.html { redirect_to @isp_subscription, notice: "Isp subscription was successfully updated." }
        format.json { render :show, status: :ok, location: @isp_subscription }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @isp_subscription.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /isp_subscriptions/1 or /isp_subscriptions/1.json
  def destroy
    @isp_subscription.destroy!

    respond_to do |format|
      format.html { redirect_to isp_subscriptions_path, status: :see_other, notice: "Isp subscription was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_isp_subscription
      @isp_subscription = IspSubscription.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def isp_subscription_params
      params.require(:isp_subscription).permit(:account_id, :next_billing_date, :payment_status, :plan_name, :features, :renewal_period, :last_payment_date)
    end
end
