class AddIndexToAccsUpdateTime < ActiveRecord::Migration[7.2]
  def change
 add_index :radacct, :acctupdatetime
  end
end
