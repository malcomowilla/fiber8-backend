Rails.application.config.middleware.use OmniAuth::Builder do
    provider(
      :auth0,
      ENV['AUTH0_CLIENT_ID'],
      ENV['AUTH0_DOMAIN'],
      ENV['AUTH0_CLIENT_SECRET'],
      callback_path: '/auth/auth0/callback',
      authorize_params: {
        scope: 'openid profile',
      },
      csrf: true # Ensure CSRF protection is enabled

    )
  end
  # http://localhost:3000/auth/auth0/callback