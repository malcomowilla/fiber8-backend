class SubscriberSerializer < ActiveModel::Serializer
  attributes :id, :name, :phone_number, :ppoe_username, :ppoe_password, :email, :ppoe_package, :date_registered, :ref_no,
   :package_name,:installation_fee, :subscriber_discount, :second_phone_number, :router_name



   def phone_number
    "#{self.object.phone_number}"
   end


   def second_phone_number
    "#{self.object.second_phone_number}"

   end
end
