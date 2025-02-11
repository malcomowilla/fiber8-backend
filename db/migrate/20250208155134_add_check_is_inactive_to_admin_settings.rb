class AddCheckIsInactiveToAdminSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :admin_settings, :check_is_inactive, :boolean, default: false
    add_column :admin_settings, :checkinactiveminutes, :string
    add_column :admin_settings, :checkinactivehrs, :string
    add_column :admin_settings, :checkinactivedays, :string
  end
end
