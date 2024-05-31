class RemoveRefNoFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :ref_no, :integer
  end
end
