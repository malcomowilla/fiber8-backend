class AddPpoeSecretsIdToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :ppoe_secrets_id, :string
  end
end
