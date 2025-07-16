class AddAggregationToPackages < ActiveRecord::Migration[7.2]
  def change
    add_column :packages, :aggregation, :string
  end
end
