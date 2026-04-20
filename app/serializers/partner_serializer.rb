class PartnerSerializer < ActiveModel::Serializer
  attributes :id, :full_name, :partner_type, :status,
   :email, :phone, :city, :country, :notes, :commission_type,
    :commission_rate, :fixed_amount, :minimum_payout,
     :payout_method, :payout_frequency, :mpesa_number, 
     :mpesa_name, :bank_name, :account_number, :account_name,
      :status, :account_id
end
