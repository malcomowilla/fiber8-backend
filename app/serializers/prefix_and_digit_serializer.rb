class PrefixAndDigitSerializer < ActiveModel::Serializer
  attributes :id, :prefix, :minimum_digits


attribute :check_update_username, if: :include_check_update_username?
attribute :check_update_password, if: :include_check_update_password?
attribute :welcome_back_message, if: :include_welcome_back_message?
attribute :router_name, if: :include_router_name_present? 



def include_router_name_present?

  context_present? 
    end
  
  
    def router_name
      instance_options[:context][:router_name]
    end
# def include_check_update_username?
#   instance_options[:context]&.fetch(:check_update_username, false)
# end

# def include_check_update_password?
#   instance_options[:context]&.fetch(:check_update_password, false)
# end

    def include_welcome_back_message?
      context_present? && instance_options[:context][:welcome_back_message] == 'true'
    end
    




def include_check_update_password?
  context_present? && instance_options[:context][:check_update_password] == 'true'

end
def include_check_update_username?
  context_present? && instance_options[:context][:check_update_username] == 'true'

end




def context_present?
  instance_options[:context].present?
end
  def check_update_username
    true
  end

def check_update_password
  true
end


def welcome_back_message
  true
end

end






