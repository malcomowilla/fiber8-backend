# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins 'http://localhost:5173'
      resource '*', headers: :any, methods: [:get, :post, :patch, :put],
      credentials: true  # Add this line if you're using cookies or session-based authentication

    end
  end

