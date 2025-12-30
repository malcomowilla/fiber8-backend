class RemoveTypeFromTemplateLocation < ActiveRecord::Migration[7.2]
  def change
    remove_column :template_locations, :type, :string
  end
end
