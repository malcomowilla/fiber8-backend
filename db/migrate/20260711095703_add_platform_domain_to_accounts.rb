class AddPlatformDomainToAccounts < ActiveRecord::Migration[7.2]
  def change
        add_column :accounts, :platform_domain, :string, default: "aitechs.co.ke", null: false

  end
end
