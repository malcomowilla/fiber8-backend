class HealthController < ApplicationController
    def up
        # render json: { status: 'UP' }, status: :ok
         render plain: 'OK'
      end
end
