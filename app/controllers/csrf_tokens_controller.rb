class CsrfTokensController < ApplicationController
    def new
        render json: { csrf_token: form_authenticity_token }
      end
end
