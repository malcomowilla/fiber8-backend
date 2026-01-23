class SubscriberInvoiceSerializer < ActiveModel::Serializer
  attributes :id, :item, :due_date, :invoice_date, :invoice_number, 
  :amount, :status, :description, :quantity, :account_id





def due_date
    object.due_date.strftime("%B %d, %Y at %I:%M %p") if object.due_date.present?
    
  end




  def invoice_date
  object.invoice_date.strftime("%B %d, %Y at %I:%M %p") if object.invoice_date.present?
end




end



