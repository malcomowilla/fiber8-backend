class AddRefNoToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :ref_no, :string
  end
end
