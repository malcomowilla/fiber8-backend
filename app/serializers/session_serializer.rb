class SessionSerializer < ActiveModel::Serializer
  attributes :id, :username



  attribute :welcome_back_message, if: :include_welcome_back_message?

  def include_welcome_back_message?
    context_present? && instance_options[:context][:welcome_back_message] == true
  end


  def context_present?
    instance_options[:context].present?
  end

  def welcome_back_message
    "Welcome Back  #{self.object.username}"
  end
end
