json.extract! subscriber, :id, :name, :phone_number, :ppoe_username, :ppoe_password, :email, :ppoe_package, :date_registered, :ref_no, :created_at, :updated_at
json.url subscriber_url(subscriber, format: :json)
