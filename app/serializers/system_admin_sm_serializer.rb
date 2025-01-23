class SystemAdminSmSerializer < ActiveModel::Serializer
  attributes :id, :user, :message, :status, :date, :system_user
end
