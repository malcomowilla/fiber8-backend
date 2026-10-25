# Recordings live on the Rails server: storage/call_recordings/<padded account id>/<uniqueid>.wav
module CallRecordingStore
  ROOT = Rails.root.join("storage", "call_recordings")
  ID = /\A[\w.\-]{1,64}\z/

  module_function

  def path(account_id, uniqueid)
    id = uniqueid.to_s
    return nil unless id.match?(ID) && !id.include?("..")

    ROOT.join(PbxId.suffix(account_id), "#{id}.wav")
  end
end