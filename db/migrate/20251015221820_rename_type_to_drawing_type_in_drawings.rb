class RenameTypeToDrawingTypeInDrawings < ActiveRecord::Migration[7.2]
  def change
        rename_column :drawings, :type, :drawing_type

  end
end
