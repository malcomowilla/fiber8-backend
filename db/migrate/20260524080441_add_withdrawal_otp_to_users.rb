class AddWithdrawalOtpToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :withdrawal_otp, :string
    add_column :users, :withdrawal_otp_sent_at, :datetime
  end
end
