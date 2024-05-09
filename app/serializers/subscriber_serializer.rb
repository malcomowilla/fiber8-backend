class SubscriberSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone_number, :ppoe_username, :ppoe_password, :email, :ppoe_package, :date_registered, :ref_no
end
