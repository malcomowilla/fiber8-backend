class RadGroupCheck < ApplicationRecord
  self.table_name = 'radgroupcheck'  # Explicitly set the table name
  acts_as_tenant(:account)


  # def attribute
  #   self[:attribute]  # Access the database column directly
  # end

  # def attribute=(val)
  #   self[:attribute] = val
  # end
    #  alias_attribute :radius_attribute, :attribute

    # default_scope { select('radcheck.*, attribute AS radius_attribute') }

end
