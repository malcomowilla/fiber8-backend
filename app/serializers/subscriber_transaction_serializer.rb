class SubscriberTransactionSerializer < ActiveModel::Serializer
  attributes :id, :transaction_type, :credit, :debit, :date, :title,
   :description, :account_id



   def credit
     "#{self.object.credit} Ksh" if object.credit.present?
   end



   def debit
     "-#{self.object.debit} Ksh" if object.debit.present?
   end

def date
  return unless object.date.present?

  date = object.date.is_a?(String) ? Time.parse(object.date) : object.date
  date.strftime("%B %d, %Y at %I:%M %p")
end
end



