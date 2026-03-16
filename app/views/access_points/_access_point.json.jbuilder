json.extract! access_point, :id, :name, :ping, :status, :checked_at, :account_id, :ip, :response, :reachable, :created_at, :updated_at
json.url access_point_url(access_point, format: :json)
