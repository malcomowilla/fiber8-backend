class CreateCdrTable < ActiveRecord::Migration[7.2]
  def change
    create_table :cdr, id: false do |t| 
      t.timestamp :calldate, null: false
      t.string :clid, limit: 80
      t.string :src, limit: 80
      t.string :dst, limit: 80
      t.string :dcontext, limit: 80
      t.string :channel, limit: 80
      t.string :dstchannel, limit: 80
      t.string :lastapp, limit: 80
      t.string :lastdata, limit: 80
      t.integer :duration
      t.integer :billsec
      t.string :disposition, limit: 45
      t.integer :amaflags
      t.string :accountcode, limit: 20
      t.string :uniqueid, limit: 150
      t.string :userfield, limit: 255
      t.string :peeraccount, limit: 20
      t.string :linkedid, limit: 150
      t.integer :account_id

    end
  end
end
