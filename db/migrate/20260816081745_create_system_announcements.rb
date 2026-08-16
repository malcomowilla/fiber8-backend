class CreateSystemAnnouncements < ActiveRecord::Migration[7.2]
  def change
    create_table :system_announcements do |t|
      t.string   :title,             null: false
      t.text     :body,              null: false
      t.string   :announcement_type, null: false, default: 'general' # feature | fix | alert | maintenance | general
      t.string   :priority,          null: false, default: 'medium'  # low | medium | high
      t.boolean  :active,            null: false, default: true
      t.datetime :published_at,      null: false
      t.datetime :expires_at
      t.string   :created_by

      t.timestamps
    end

    add_index :system_announcements, :active
    add_index :system_announcements, :published_at
  end
end
