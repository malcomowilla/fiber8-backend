class AddTemplateTypeToTemplateLocation < ActiveRecord::Migration[7.2]
  def change
    add_column :template_locations, :template_type, :string
  end
end
