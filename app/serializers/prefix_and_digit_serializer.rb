class PrefixAndDigitSerializer < ActiveModel::Serializer
  attributes :id, :prefix, :minimum_digits


attribute :check_update_username, if: :include_check_update_username?
attribute :check_update_password, if: :include_check_update_password?

# def include_check_update_username?
#   instance_options[:context]&.fetch(:check_update_username, false)
# end

# def include_check_update_password?
#   instance_options[:context]&.fetch(:check_update_password, false)
# end


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
end






