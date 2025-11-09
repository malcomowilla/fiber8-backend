class AdSettingSerializer < ActiveModel::Serializer
  attributes :id, :enabled, :to_right, :to_left, :to_top, :account_id
end
