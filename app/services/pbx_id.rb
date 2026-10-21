module PbxId
  WIDTH = 5
  SHORT = /\A\d{3,5}\z/
  MAX_ACCOUNT_ID = (10**WIDTH) - 1

  module_function

  def suffix(account_id)
    id = account_id.to_i
    raise ArgumentError, "Account id too large for PBX id" if id <= 0 || id > MAX_ACCOUNT_ID

    id.to_s.rjust(WIDTH, "0")
  end

  def build(extension, account_id)
    "#{extension}#{suffix(account_id)}"
  end

  # "PJSIP/200400017-0000001a" => "200400017"
  def from_channel(channel)
    channel.to_s[%r{\APJSIP/(\d+)-}, 1]
  end
end