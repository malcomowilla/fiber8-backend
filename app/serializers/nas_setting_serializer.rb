class NasSettingSerializer < ActiveModel::Serializer
  attributes :id, :notification_when_unreachable, :unreachable_duration_minutes, :notification_phone_number
end
