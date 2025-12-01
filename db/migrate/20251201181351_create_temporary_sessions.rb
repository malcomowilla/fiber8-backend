class CreateTemporarySessions < ActiveRecord::Migration[7.2]
  def change
    create_table :temporary_sessions do |t|
      t.string :session
      t.string :ip
      t.integer :account_id

      t.timestamps
    end
  end
end



