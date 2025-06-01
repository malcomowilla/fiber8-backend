class CreateChangeLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :change_logs do |t|
      t.string :version
      t.text :system_changes, array: true, default: []  # For PostgreSQL array type

      t.string :change_title

      t.timestamps
    end
  end
end
