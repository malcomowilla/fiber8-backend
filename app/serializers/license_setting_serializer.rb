class LicenseSettingSerializer < ActiveModel::Serializer
  attributes :id, :expiry_warning_days, :phone_notification, :phone_number
end
