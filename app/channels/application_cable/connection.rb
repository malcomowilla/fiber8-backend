# module ApplicationCable
#   class Connection < ActionCable::Connection::Base

#   rescue_from StandardError, with: :connection_error
#     identified_by :current_user


#     def connect
#       self.current_user = find_verified_user
#     end

#     private
#       def find_verified_user
#         if verified_user = User.find_by(id: cookies.encrypted[:user_id])
#           verified_user
#         else
#           reject_unauthorized_connection
#         end
#       end
#       private
#       def connection_error(e)
#         SomeExternalBugtrackingService.notify(e)
#       end
#   end
# end

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    rescue_from StandardError, with: :report_error

    identified_by :current_user


    
     
    # def connect
    #   session = cookies.encrypted['_fiber8backend_session']
    #   user_id = session['user_id'] if session.present?

    #   self.current_user = (user_id.present? && User.find_by(id: user_id))

    #   reject_unauthorized_connection unless current_user

         

    # end


    # def connect
    #   self.current_user = find_verified_user
    #   ActsAsTenant.current_tenant = current_user.account

    # end

    # private
    #   def find_verified_user
    #     if verified_user = User.find_by(id: cookies.encrypted['_fiber8backend_session']['user_id'])
    #       verified_user
    #     else
    #       reject_unauthorized_connection
    #     end
    #   end




    # def connect
    #   session = cookies.encrypted['_fiber8backend_session']
    #   user_id = session['user_id']
    #   account_id = session['account_id']

    #   if user_id.present? && account_id.present?
    #     # Fetch the User object using user_id
        
    #     user = User.find_by(id: user_id)
    #     account = Account.find_by(id: account_id)

    #     # Set the current_user if user is found
    #     if user
    #       self.current_user = user

    #       ActsAsTenant.with_tenant(current_user.account) do
    #         # Additional connection logic here
    #       end
          
    #     else
    #       # Reject the connection if user is not found
    #       reject_unauthorized_connection
    #     end
    #   else
    #     # Reject the connection if user_id is not present in session
    #     reject_unauthorized_connection
    #   end
    # end




    private
    def report_error(e)
      SomeExternalBugtrackingService.notify(e)
    end
  end
end