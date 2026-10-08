class AddCompensationFieldsToTemporarySessions < ActiveRecord::Migration[7.2]
  def change
    add_column :temporary_sessions, :compensation_status, :string
    add_column :temporary_sessions, :compensated_at, :datetime
    add_column :temporary_sessions, :compensated_minutes, :integer
    add_index  :temporary_sessions, :compensation_status
  end
end
