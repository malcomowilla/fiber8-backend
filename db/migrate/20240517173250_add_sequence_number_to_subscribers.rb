class AddSequenceNumberToSubscribers < ActiveRecord::Migration[7.1]
  def change
    # add_column :subscribers, :sequence_number, :integer , auto_increment: true
    # add_index :subscribers, :sequence_number
    # 
    # def change
    # Adding the column without the auto-increment setup
 add_column :subscribers, :sequence_number, :integer

 # Create a sequence
 execute <<-SQL
   CREATE SEQUENCE subscribers_sequence_number_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
 SQL

 # Set the sequence as the default value for the column
 execute <<-SQL
   ALTER TABLE subscribers ALTER COLUMN sequence_number SET DEFAULT nextval('subscribers_sequence_number_seq');
 SQL
  end
end



