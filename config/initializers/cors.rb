# # config/initializers/cors.rb

# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#     allow do
#       origins '*'
#       # resource '*', headers: :any, methods: [:get, :post, :patch, :put],
#          resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head],

#       credentials: false  # Add this line if you're using cookies or session-based authentication

#     end
#   end







Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options],
      credentials: false
  end
end