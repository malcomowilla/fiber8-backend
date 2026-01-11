class RemoveUnreachableMinutesFromNasSettings < ActiveRecord::Migration[7.2]
  def change
    remove_column :nas_settings, :unreachable_duration_minutes, :string
  end
end
