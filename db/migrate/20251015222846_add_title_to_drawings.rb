class AddTitleToDrawings < ActiveRecord::Migration[7.2]
  def change
    add_column :drawings, :title, :string
  end
end
