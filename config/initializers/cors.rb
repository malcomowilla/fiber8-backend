# config/initializers/cors.rb

Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins 'https://fiber8.aitechs.co.ke'
      # resource '*', headers: :any, methods: [:get, :post, :patch, :put],
         resource '*', headers: :any, methods: [:get, :post, :put, :patch, :delete, :options, :head],

      credentials: true  # Add this line if you're using cookies or session-based authentication

    end
  end




# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins ->(origin, _env) {
#       origin.present? && (origin ==  origin.match?(/^https:\/\/.*\.aitechs\.co\.ke$/) || "https://aitechs.co.ke" == origin)
#     }
#     resource "*",
#     expose: ['Content-Disposition'],
#     headers: :any, methods: [:get, :post, :patch, :put, :delete, :options]
#   end
# end

