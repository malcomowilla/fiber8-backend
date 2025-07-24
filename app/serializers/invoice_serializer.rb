class InvoiceSerializer < ActiveModel::Serializer
  attributes :id, :invoice_number, :invoice_date, :due_date, :total, :status, :account_id,
  :invoice_desciption




  def due_date
    object.due_date.strftime("%B %d, %Y at %I:%M %p") if object.due_date.present?
    
  end




  def invoice_date
  object.invoice_date.strftime("%B %d, %Y at %I:%M %p") if object.invoice_date.present?
end

end



