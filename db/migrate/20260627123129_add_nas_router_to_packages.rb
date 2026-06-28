class AddNasRouterToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :nas_router, :string
  end
end
