class AddUnreachableMinutesToNasSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_settings, :unreachable_duration_minutes, :integer
  end
end
