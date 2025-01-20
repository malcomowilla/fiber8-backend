class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.string :welcome_message

      t.timestamps
    end
  end
end
