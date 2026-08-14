# frozen_string_literal: true

# Shared by PopsController, NetworkDevicesController, NetworkConnectionsController,
# KmlImportsController. If your app already has a shared tenant-resolution
# concern (likely, given ActsAsTenant is used across the codebase), prefer
# that one instead and drop this file.
module NetworkMapTenantScoped
  extend ActiveSupport::Concern

  included do
    before_action :require_login
    before_action :set_tenant
  end

  private

  def set_tenant
    host = request.headers['X-Subdomain']
    @account = Account.find_by(subdomain: host)
    return render json: { error: 'Invalid tenant' }, status: :not_found unless @account

    ActsAsTenant.current_tenant = @account
  end
end