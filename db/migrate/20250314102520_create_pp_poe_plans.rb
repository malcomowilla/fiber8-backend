class CreatePpPoePlans < ActiveRecord::Migration[7.2]
  def change
    create_table :pp_poe_plans do |t|
      t.string :maximum_pppoe_subscribers

      t.timestamps
    end
  end
end
