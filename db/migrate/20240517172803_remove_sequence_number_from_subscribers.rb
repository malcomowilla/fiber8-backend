class RemoveSequenceNumberFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :sequence_number, :integer
  end
end
