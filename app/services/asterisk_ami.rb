require "ruby-asterisk"

class AsteriskAmi
  CONTACT_LINE = /Contact:\s+(?<aor>[^\/\s]+)\/(?<uri>\S+)\s+\S+\s+(?<state>Unavail|Avail|NonQual|Unknown|Removed|Created)\b\s*(?<rtt>[\d.]+)?/i

  def initialize
    @host = ENV.fetch("ASTERISK_AMI_HOST")
    @port = ENV.fetch("ASTERISK_AMI_PORT", "5038").to_i
    @username = ENV.fetch("ASTERISK_AMI_USERNAME")
    @secret = ENV.fetch("ASTERISK_AMI_SECRET")
  end

  # { "1001" => { contacts:, available:, unavailable:, via: "webrtc"|"sip_phone", ip:, rtt: } }
  def contacts
    result = {}
    run("pjsip show contacts").each_line do |line|
      m = line.match(CONTACT_LINE)
      next unless m

      uri = m[:uri]
      entry = (result[m[:aor]] ||= { contacts: 0, available: 0, unavailable: 0, via: nil, ip: nil, rtt: nil })
      entry[:contacts] += 1
      if m[:state].match?(/\A(Avail|NonQual)\z/i)
        entry[:available] += 1
      else
        entry[:unavailable] += 1
      end
      entry[:via] ||= uri.match?(/transport=wss?\b/i) ? "webrtc" : "sip_phone"
      entry[:ip]  ||= uri[/@([^;:>]+)/, 1]
      entry[:rtt] ||= m[:rtt]&.to_f
    end
    result
  end

  def contact_status(extension:)
    extension = extension.to_s
    raise ArgumentError, "Invalid extension" unless extension.match?(/\A\d{3,10}\z/)

    c = contacts[extension]
    return { registered: false, status: "offline", reachability: "unknown", contacts: 0, via: nil } unless c

    {
      registered: true,
      status: c[:available].positive? ? "online" : "offline",
      reachability: c[:available].positive? ? "reachable" : "unreachable",
      contacts: c[:contacts],
      via: c[:via]
    }
  end

  # Live channels from `core show channels concise`, de-duplicated into calls.
  def live_calls(extensions: nil)
    mine = extensions&.map(&:to_s)
    channels = run("core show channels concise").lines.filter_map { |l| parse_channel(l.strip) }
    names = channels.map { |c| c[:channel] }

    channels.reject! do |c|
      c[:bridged] && names.include?(c[:bridged]) && c[:channel] > c[:bridged]
    end

    channels.select! do |c|
      mine.nil? || [c[:endpoint], c[:caller_id], c[:with]].compact.any? { |x| mine.include?(x) }
    end

    channels.map do |c|
      {
        channel: c[:channel],
        endpoint: c[:endpoint],
        with: c[:with],
        caller_id: c[:caller_id],
        state: c[:bridged] ? "talking" : c[:state].to_s.downcase,
        seconds: c[:seconds]
      }
    end
  end

  private

  # Concise format: name!ctx!exten!prio!state!app!data!callerid!acct!peeracct!amaflags!duration!bridged!uniqueid
  def parse_channel(line)
    f = line.split("!")
    return unless f.size >= 13 && f[0].start_with?("PJSIP/")

    bridged = f[12] == "(None)" ? nil : f[12]
    {
      channel: f[0],
      endpoint: endpoint_of(f[0]),
      state: f[4],
      caller_id: f[7].presence,
      seconds: f[11].to_i,
      bridged: bridged,
      with: bridged && endpoint_of(bridged)
    }
  end

  def endpoint_of(channel)
    channel[%r{/([^/]+)-[0-9a-f]+\z}i, 1]
  end

  def run(command)
    ami = RubyAsterisk::AMI::Client.new(host: @host, port: @port)

    begin
      ami.connect

      login = ami.login(username: @username, secret: @secret).value(5)
      raise "AMI login failed" unless login.success

      ami.command(command).value(5).raw_response.to_s
    ensure
      begin
        ami.disconnect
      rescue StandardError
        # Do not hide the original request error.
      end
    end
  end
end