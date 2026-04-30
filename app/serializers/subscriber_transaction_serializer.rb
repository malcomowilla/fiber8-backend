class SubscriberTransactionSerializer < ActiveModel::Serializer
  attributes :id, :transaction_type, :credit, :debit, :date, :title,
   :description, :account_id



   def date
     object.date.strftime("%B %d, %Y at %I:%M %p") if object.date.present?
   end
end



