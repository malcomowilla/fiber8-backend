class RadGroupReply < ApplicationRecord

  self.table_name = 'radgroupreply'  # Explicitly set the table name
  # def attribute
  #   self[:attribute]  # Access the database column directly
  # end

  # def attribute=(val)
  #   self[:attribute] = val
  # end

  alias_attribute :radius_attribute, :attribute

end
