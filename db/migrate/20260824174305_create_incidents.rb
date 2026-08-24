class CreateIncidents < ActiveRecord::Migration[7.2]
  def change
    create_table :incidents do |t|
      t.string   :title, null: false
      t.string   :incident_type, null: false, default: 'outage'   # outage | maintenance | degradation
      t.string   :status, null: false, default: 'ongoing'         # ongoing | resolved
      t.datetime :start_time, null: false
      t.datetime :end_time
      t.text     :notes
      t.string   :router_scope, null: false, default: 'all'       # all | specific
      t.json     :affected_routers, default: []                   # array of NasRouter names
      t.string   :service_type, null: false, default: 'hotspot'   # hotspot | pppoe | both
      t.boolean  :compensate, null: false, default: false
      t.boolean  :active_customers_only, null: false, default: false
      t.datetime :compensated_at
      t.integer  :compensated_count, default: 0
      t.integer  :sms_sent_count, default: 0
      t.references :account, null: false, foreign_key: true
      t.timestamps
    end
    add_index :incidents, [:account_id, :start_time]
  end
end
