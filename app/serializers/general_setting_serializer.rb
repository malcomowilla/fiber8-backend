class GeneralSettingSerializer < ActiveModel::Serializer
  attributes :id, :title, :timezone, :allowed_ips, :account_id
end
