class AddTvPlanIdToTemporarySessions < ActiveRecord::Migration[7.2]
  def change
        add_reference :temporary_sessions, :tv_plan, null: true, foreign_key: true

  end
end
