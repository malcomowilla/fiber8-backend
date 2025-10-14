class AddIsEmailVerifiedToTechnicians < ActiveRecord::Migration[7.2]
  def change
    add_column :technicians, :is_email_verified, :boolean
  end
end
