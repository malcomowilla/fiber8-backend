class AddStandard1ToOnu < ActiveRecord::Migration[7.2]
  def change
    add_column :onus, :standard1, :string
  end
end
