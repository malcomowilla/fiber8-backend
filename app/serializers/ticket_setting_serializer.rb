

class TicketSettingSerializer < ActiveModel::Serializer
 attributes :prefix, :minimum_digits, :id, :account_id
end
