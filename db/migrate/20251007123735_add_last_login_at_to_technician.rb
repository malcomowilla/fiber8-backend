class AddLastLoginAtToTechnician < ActiveRecord::Migration[7.2]
  def change
    add_column :technicians, :last_login_at, :datetime
  end
end
