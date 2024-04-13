class AddDomainToAccount < ActiveRecord::Migration[7.1]
  def change
    add_column :accounts, :domain, :string
  end
end
