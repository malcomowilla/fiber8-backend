class AddButtonNameToAnalyticsEvent < ActiveRecord::Migration[7.2]
  def change
    add_column :analytics_events, :button_name, :string
  end
end
