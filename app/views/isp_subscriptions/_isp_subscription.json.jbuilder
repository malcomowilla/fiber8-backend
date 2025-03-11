json.extract! isp_subscription, :id, :account_id, :next_billing_date, :payment_status, :plan_name, :features, :renewal_period, :last_payment_date, :created_at, :updated_at
json.url isp_subscription_url(isp_subscription, format: :json)
