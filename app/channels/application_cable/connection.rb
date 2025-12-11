

# module ApplicationCable
#   class Connection < ActionCable::Connection::Base
#     identified_by :current_user

#     def connect
#       self.current_user = find_verified_user
#     end

#     private

#     def find_verified_user
#       token = cookies.encrypted.signed[:jwt_user]
#        decoded_token = JWT.decode(token, ENV['JWT_SECRET'], true, algorithm: 'HS256')
#           user_id = decoded_token[0]['user_id']
#       if current_user = User.find_by(id: user_id )
#         current_user
#       else
#         reject_unauthorized_connection
#       end
#     end
#   end
# end

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_session

    def connect
      # If hotspot session: use IP connection
      if request.params["X-ip"].present?
        connect_hotspot_user
      else
        # Otherwise use JWT-based authentication
        connect_authenticated_user
      end
    end

    private

   
    def connect_hotspot_user
      ip = request.params["X-ip"]
      session = TemporarySession.find_by(ip: ip)

      if session
        self.current_session = session
      else
        reject_unauthorized_connection
      end
    end

    ##
    # ADMIN or CUSTOMER (Authenticated) connection
    ##
    def connect_authenticated_user
      token = cookies.encrypted.signed[:jwt_user]
      decoded = JWT.decode(token, ENV["JWT_SECRET"], true, algorithm: "HS256")
      user_id = decoded[0]["user_id"]

      user = User.find_by(id: user_id)

      if user
        self.current_user = user
      else
        reject_unauthorized_connection
      end
    end
  end
end
