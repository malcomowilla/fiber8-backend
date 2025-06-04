class EventTitleSerializer < ActiveModel::Serializer
  attributes :id, :start_date_time, :end_date_time, :title, :start, :end, :account_id
end
