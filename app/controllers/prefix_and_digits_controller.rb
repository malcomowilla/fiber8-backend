class PrefixAndDigitsController < ApplicationController

set_current_tenant_through_filter

before_action :set_my_tenant


def set_my_tenant
    set_current_tenant(current_user.account)
  end
def create
    @prefix_and_digit =  PrefixAndDigit.new( prefix_and_digits_params)

   render json: @prefix_and_digit, status: :created 
  end


private
  def prefix_and_digits_params
    params.require(:prefix_and_digit).permit(:prefix, :minimum_digits)
  end
  
end
