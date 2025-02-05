class AddPpoEprofileIdToPackages < ActiveRecord::Migration[7.1]
  def change
    add_column :packages, :ppoe_profile_id, :string
  end
end
