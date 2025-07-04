class ActivtyLogSerializer < ActiveModel::Serializer
  attributes :id, :action, :subject, :description, :user, :date, :account_id,
  :ip, :user_agent



  def date
    object.date.strftime("%B %d, %Y at %I:%M %p") if object.date.present?
  end
end






