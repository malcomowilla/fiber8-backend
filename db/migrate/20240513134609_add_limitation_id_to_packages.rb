class AddLimitationIdToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :limitation_id, :string
  end
end
