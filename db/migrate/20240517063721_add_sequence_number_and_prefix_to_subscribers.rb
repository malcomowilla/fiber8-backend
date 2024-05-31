class AddSequenceNumberAndPrefixToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :sequence_number, :integer
    add_column :subscribers, :prefix, :string
  end
end
