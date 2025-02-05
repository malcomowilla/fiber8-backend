class SmSerializer < ActiveModel::Serializer
  attributes :id, :user, :message, :date, :status, :admin_user, :system_user, :account_id
end
