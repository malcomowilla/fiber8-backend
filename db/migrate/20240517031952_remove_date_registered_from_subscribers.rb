class RemoveDateRegisteredFromSubscribers < ActiveRecord::Migration[7.1]
  def change
    remove_column :subscribers, :date_registered, :date
  end
end
