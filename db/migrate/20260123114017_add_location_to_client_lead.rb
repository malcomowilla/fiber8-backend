class AddLocationToClientLead < ActiveRecord::Migration[7.2]
  def change
    add_column :client_leads, :location, :string
  end
end
