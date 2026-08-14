class SetUseRadiusDefaultFalse < ActiveRecord::Migration[7.2]
  def up
    change_column_default :nas_settings, :use_radius, false
    NasSetting.where(use_radius: nil).update_all(use_radius: false)
    change_column_null :nas_settings, :use_radius, false, default: false
  end

  def down
    change_column_null :nas_settings, :use_radius, true
    change_column_default :nas_settings, :use_radius, nil
  end
end
