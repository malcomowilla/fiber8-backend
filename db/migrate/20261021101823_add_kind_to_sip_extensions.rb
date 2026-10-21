class AddKindToSipExtensions < ActiveRecord::Migration[7.2]
  def change
     add_column :sip_extensions, :kind, :string, null: false, default: "webrtc"
  end
end
