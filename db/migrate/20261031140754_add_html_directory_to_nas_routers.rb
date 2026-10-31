class AddHtmlDirectoryToNasRouters < ActiveRecord::Migration[7.2]
  def change
    add_column :nas_routers, :html_directory, :string, default: nil
  end
end
