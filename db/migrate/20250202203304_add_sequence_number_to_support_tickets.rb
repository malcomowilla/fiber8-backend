class AddSequenceNumberToSupportTickets < ActiveRecord::Migration[7.1]
  def change
    add_column :support_tickets, :sequence_number, :integer

 # Create a sequence
 execute <<-SQL
   CREATE SEQUENCE support_tickets_sequence_number_seq START WITH 1 INCREMENT BY 1 NO MINVALUE NO MAXVALUE CACHE 1;
 SQL

 # Set the sequence as the default value for the column
 execute <<-SQL
   ALTER TABLE support_tickets ALTER COLUMN sequence_number SET DEFAULT nextval('support_tickets_sequence_number_seq');
 SQL
end


  
end
