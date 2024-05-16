class AddProfileLimitationIdToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :profile_limitation_id, :string
  end
end
