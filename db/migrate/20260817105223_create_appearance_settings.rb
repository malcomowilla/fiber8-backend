class CreateAppearanceSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :appearance_settings do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.string :color_hsl, null: false, default: '173 80% 24%'
      t.string :color_preset_id, default: 'teal'
      t.string :font_key, default: 'plexMono'
      t.string :display_font_key, default: 'plexMono'
      t.boolean :font_italic, default: false
      t.boolean :display_font_italic, default: false
      t.string :radius, default: 'balanced'
      t.string :density, default: 'comfortable'
      t.string :mode, default: 'system'

      t.timestamps
    end
  end
end
