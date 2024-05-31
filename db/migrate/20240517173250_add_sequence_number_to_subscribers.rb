class AddSequenceNumberToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :sequence_number, :integer , auto_increment: true
    add_index :subscribers, :sequence_number
  end
end
