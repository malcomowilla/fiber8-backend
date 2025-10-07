class TechnicianSerializer < ActiveModel::Serializer
  attributes :id, :email, :username, :phone_number, :password_digest, :account_id
end
