class CalendarSettingSerializer < ActiveModel::Serializer
  attributes :id, :start_in_hours, :start_in_minutes, :account_id
end
