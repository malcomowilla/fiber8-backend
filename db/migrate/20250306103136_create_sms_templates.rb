class CreateSmsTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :sms_templates do |t|
      t.string :send_voucher_template
      t.string :voucher_template
      t.integer :account_id

      t.timestamps
    end
  end
end
