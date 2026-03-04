class AddIndexToRefNoSubscriber < ActiveRecord::Migration[7.2]
  def change
    add_index :subscribers, :ref_no
  end
end
