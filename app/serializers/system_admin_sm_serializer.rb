class SystemAdminSmSerializer < ActiveModel::Serializer
  attributes :id, :user, :message, :status, :date, :system_user


  def date
    object.date.strftime("%B %d, %Y at %I:%M %p") if object.date.present?
  end

end
