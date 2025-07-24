# module ApplicationCable
#   class Connection < ActionCable::Connection::Base
#     identified_by :current_account

#     def connect
#       self.current_account = find_verified_account
#       logger.add_tags 'ActionCable', current_account.class.name, current_account.id
#     rescue StandardError
#       reject_unauthorized_connection
#     end

#     private

#     def find_verified_account
#       # Check for admin JWT
#       admin_token = cookies.encrypted.signed[:jwt_user]
#       if admin_token
#         begin
#           decoded_token = JWT.decode(admin_token, ENV['JWT_SECRET'], true, algorithm: 'HS256')
#           user_id = decoded_token[0]['user_id']
#           return User.find_by(id: user_id) if user_id
#         rescue JWT::DecodeError
#           # Token decode failed
#         end
#       end

#       # Check for customer JWT
#       customer_token = cookies.encrypted.signed[:customer_jwt]
#       if customer_token
#         begin
#           decoded_token = JWT.decode(customer_token, ENV['JWT_SECRET'], true, algorithm: 'HS256')
#           customer_id = decoded_token[0]['customer_id']
#           return Customer.find_by(id: customer_id) if customer_id
#         rescue JWT::DecodeError
#           # Token decode failed
#         end
#       end

#       # Reject connection if neither admin nor customer is found
#       reject_unauthorized_connection
#     end
#   end
# end

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      if current_user = User.find_by(id: cookies.encrypted.signed[:jwt_user])
        current_user
      else
        reject_unauthorized_connection
      end
    end
  end
end

