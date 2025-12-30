class CompanyFinancialRecordSerializer < ActiveModel::Serializer
  attributes :id, :category, :is_intercompany, :amount, :description,
   :transaction_type, :company, :date, :counterparty,  :reference



end
