class EquipmentSerializer < ActiveModel::Serializer
  attributes :id, :user, :device_type, :name, :model, :serial_number, :price, :amount_paid, :account_number
end
