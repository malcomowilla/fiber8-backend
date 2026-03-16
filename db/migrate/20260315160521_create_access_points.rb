class CreateAccessPoints < ActiveRecord::Migration[7.2]
  def change
    create_table :access_points do |t|
      t.string :name
      t.string :ping
      t.string :status
      t.datetime :checked_at
      t.integer :account_id
      t.string :ip
      t.string :response
      t.string :reachable

      t.timestamps
    end
  end
end
