class Auth0Controller < ApplicationController
  def callback
    auth_info = request.env['omniauth.auth']
    session[:userinfo] = auth_info['extra']['raw_info']
    redirect_to 'http://localhost:5173/layout/admin-dashboard' # Redirect to your frontend app after successful authentication

  end

  def failure
    render json: { error: "Authentication failed. Please try again." }, status: :unprocessable_entity
  end
end
