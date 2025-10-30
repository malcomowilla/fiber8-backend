


class SubscriptionPaymentController < ApplicationController
  # before_action :set_subscription_payment, only: %i[ show edit update destroy ]

# load_and_authorize_resource except: [:allow_get_subscription_payments]

  set_current_tenant_through_filter
  before_action :set_tenant
  before_action :update_last_activity

  

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    ActsAsTenant.current_tenant = @account
    EmailConfiguration.configure(@account, ENV['SYSTEM_ADMIN_EMAIL'])
    # EmailSystemAdmin.configure(@current_account, current_system_admin)
  
    # set_current_tenant(@account)
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Invalid tenant' }, status: :not_found
  
    
  end



  def make_subscription_payment
    plan_type = params[:plan_type]
expiry_days = params[:plan][:expiry_days]


    if plan_type == 'pppoe'
        @plan = PpPoePlan.first_or_initialize(
      name: params[:plan][:name],
      maximum_pppoe_subscribers: params[:plan][:maximum_pppoe_subscribers],
      expiry_days: params[:plan][:expiry_days],
      price: params[:plan][:price],
      status: "active",
  expiry:  Time.current + expiry_days.days,
    plan_name:"PPPoE Plan #{params[:plan][:name]}",


    )
@plan.update(
     name: params[:plan][:name],
      maximum_pppoe_subscribers: params[:plan][:maximum_pppoe_subscribers],
      expiry_days: params[:plan][:expiry_days],
       price: params[:plan][:price],
       status: "active",
         expiry:  Time.current + expiry_days.days,
         plan_name:"PPPoE Plan #{params[:plan][:name]}",


)

Invoice.create(
  invoice_number: generate_invoice_number,
  plan_name: @plan.name,
  invoice_date: Time.current,
  due_date:   Time.current + expiry_days.days,
  invoice_desciption: @plan.name,
  total: @plan.price,
  status: "paid",
  last_invoiced_at: Time.current,


)
    if @plan.save

      render json: @plan, status: :created
    else
      render json: { errors: @plan.errors }, status: :unprocessable_entity
      end

      
    elsif plan_type == 'hotspot'
       @hotspot_plan = HotspotPlan.first_or_initialize(
      name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
       price: params[:plan][:price],
       status: "active",
         expiry:  Time.current + expiry_days.days,
         plan_name:"Hotspot Plan #{params[:plan][:name]}",

    )
@hotspot_plan.update(
   name: params[:plan][:name],
      hotspot_subscribers: params[:plan][:hotspot_subscribers],
      expiry_days: params[:plan][:expiry_days],
       price: params[:plan][:price],
       status: "active",
         expiry:  Time.current + expiry_days.days,
         plan_name:"Hotspot Plan #{params[:plan][:name]}"


)



Invoice.create(
  invoice_number: generate_invoice_number,
  plan_name: @hotspot_plan.name,
  invoice_date: Time.current,
      due_date:  Time.current + expiry_days.days,
  invoice_desciption: @hotspot_plan.name,
  total: @hotspot_plan.price,
  status: "paid",
last_invoiced_at: Time.current,

)

    if  @hotspot_plan.save
      render json:  @hotspot_plan, status: :created
    else
      render json: { errors:@hotspot_plan.errors }, status: :unprocessable_entity
      end

      
    end


    

  end


   def update_last_activity
if current_user
      current_user.update!(last_activity_active: Time.current)
    end
    
  end


  private
  def generate_invoice_number
    "INV#{Time.current.strftime("%Y%m%d%H%M%S")}#{rand(100..999)}"
  end

end