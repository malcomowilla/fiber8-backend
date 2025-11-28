class AddDialStatusToCdr < ActiveRecord::Migration[7.2]
  def change
    add_column :cdr, :dialstatus, :string, limit: 20
  end
end









