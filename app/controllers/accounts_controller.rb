class AccountsController < ApplicationController
  # before_action :set_account, only: %i[ show edit update destroy ]

  # def index
  #   @accounts = Account.all
  # end

  # def show
  # end




  def index
    @accounts = Account.all.includes(:users)
    render json:  @accounts
  end
 
  def create
    @account = Account.new(account_params)

    respond_to do |format|
      if @account.save
        format.html { redirect_to account_url(@account), notice: "Account was successfully created." }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end


 
  private
    def set_account
      @account = Account.find(params[:id])
    end

    # def account_params
    #   params.require(:account).permit(:name, :subdomain)
    # end
end
