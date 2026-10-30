
# # Minimal RouterOS binary API client (port 8728). No external gem needed.
# # Handles both legacy MD5-challenge login (RouterOS < 6.43) and the
# # newer plain login (RouterOS >= 6.43) automatically.
# class RouterosApiClient
#   class ApiError < StandardError; end

#   def initialize(host, username, password, port: 8728, timeout: 10)
#     @host = host
#     @username = username
#     @password = password
#     @port = port
#     @timeout = timeout
#   end

#   def connect
#     @socket = Socket.tcp(@host, @port, connect_timeout: @timeout)
#     login!
#     self
#   end

#   def talk(sentence)
#     write_sentence(sentence)
#     read_all_replies
#   end

#   def close
#     @socket&.close
#   rescue
#     nil
#   end

#   private

#   def login!
#     write_sentence(['/login', "=name=#{@username}", "=password=#{@password}"])
#     reply = read_sentence

#     if reply.first == '!trap'
#       raise ApiError, extract_message(reply)
#     end

#     ret = reply.find { |w| w.start_with?('=ret=') }
#     return if ret.nil?

#     challenge = ret.sub('=ret=', '')
#     require 'digest/md5'
#     md5 = Digest::MD5.digest("\x00" + @password + [challenge].pack('H*'))
#     response = "00" + md5.unpack1('H*')

#     write_sentence(['/login', "=name=#{@username}", "=response=#{response}"])
#     second_reply = read_sentence
#     raise ApiError, extract_message(second_reply) if second_reply.first == '!trap'
#   end

#   def extract_message(reply)
#     msg_word = reply.find { |w| w.start_with?('=message=') }
#     msg_word ? msg_word.sub('=message=', '') : reply.join(' ')
#   end

#   def read_all_replies
#     sentences = []
#     loop do
#       sentence = read_sentence
#       sentences << sentence
#       break if sentence.first == '!done' || sentence.first == '!trap'
#     end
#     sentences
#   end

#   def write_sentence(words)
#     words.each { |w| write_word(w) }
#     write_word('')
#   end

#   def write_word(word)
#     bytes = word.b
#     @socket.write(encode_length(bytes.bytesize))
#     @socket.write(bytes)
#   end

#   def read_sentence
#     words = []
#     loop do
#       word = read_word
#       break if word.nil? || word.empty?
#       words << word
#     end
#     words
#   end

#   def read_word
#     length = read_length
#     return nil if length.nil? || length.zero?
#     read_exact(length)
#   end

#   def read_length
#     first_byte = read_exact(1)
#     return nil if first_byte.nil?
#     b0 = first_byte.unpack1('C')

#     if b0 & 0x80 == 0x00
#       b0
#     elsif b0 & 0xC0 == 0x80
#       b1 = read_exact(1).unpack1('C')
#       ((b0 & 0x3F) << 8) | b1
#     elsif b0 & 0xE0 == 0xC0
#       rest = read_exact(2).unpack('C2')
#       ((b0 & 0x1F) << 16) | (rest[0] << 8) | rest[1]
#     elsif b0 & 0xF0 == 0xE0
#       rest = read_exact(3).unpack('C3')
#       ((b0 & 0x0F) << 24) | (rest[0] << 16) | (rest[1] << 8) | rest[2]
#     else
#       read_exact(4).unpack1('N')
#     end
#   end

#   def read_exact(n)
#     buf = @socket.read(n)
#     raise ApiError, "Connection closed by router" if buf.nil? || buf.bytesize < n
#     buf
#   end

#   def encode_length(len)
#     if len < 0x80
#       [len].pack('C')
#     elsif len < 0x4000
#       [len | 0x8000].pack('n')
#     elsif len < 0x200000
#       [(len | 0xC00000) >> 16, len & 0xFFFF].pack('Cn')
#     elsif len < 0x10000000
#       [(len | 0xE0000000) >> 24, (len >> 8) & 0xFFFF, len & 0xFF].pack('CnC')
#     else
#       [0xF0, len].pack('CN')
#     end
#   end
# end
require 'socket'
require 'timeout'
require 'digest/md5'

# Minimal RouterOS binary API client (port 8728). No external gem needed.
# Handles both legacy MD5-challenge login (RouterOS < 6.43) and the
# newer plain login (RouterOS >= 6.43) automatically.
#
#   RouterosApiClient.open(ip, user, pass) do |api|
#     api.print('/system/resource')          # => [{ 'board-name' => '...', ... }]
#     api.count('/ppp/active')               # => 198
#     api.talk(['/user/set', '=.id=*1', '=password=secret'])
#   end
class RouterosApiClient
  class ApiError < StandardError; end

  def self.open(host, username, password, **opts)
    client = new(host, username, password, **opts).connect
    begin
      yield client
    ensure
      client.close
    end
  end

  def initialize(host, username, password, port: 8728, timeout: 10)
    @host = host
    @username = username
    @password = password.to_s
    @port = port
    @timeout = timeout
  end

  def connect
    @socket = Socket.tcp(@host, @port, connect_timeout: @timeout)
    login!
    self
  rescue SystemCallError, SocketError => e
    close
    raise ApiError, "Cannot reach #{@host}:#{@port} (#{e.message}). Make sure the API service is enabled on the router."
  end

  # Sends one command, returns every sentence up to and including !done.
  # Raises ApiError if the router answers with !trap / !fatal.
  def talk(sentence)
    write_sentence(sentence)
    read_all_replies
  end

  # Returns an array of hashes, one per !re row.
  #   print('/ip/address')
  #   print('/user', ['?name=admin'])
  #   print('/log', proplist: %w[time topics message])
  def print(path, query = [], proplist: nil)
    words = ["#{path}/print"]
    words << "=.proplist=#{proplist.join(',')}" if proplist
    words.concat(query)
    talk(words).select { |s| s.first == '!re' }.map { |s| parse_attributes(s) }
  end

  # Fast row count (e.g. active sessions) without pulling every row.
  def count(path)
    replies = talk(["#{path}/print", '=count-only='])
    ret = replies.flatten.find { |w| w.start_with?('=ret=') }
    ret ? ret.sub('=ret=', '').to_i : replies.count { |s| s.first == '!re' }
  end

  def close
    @socket&.close
  rescue StandardError
    nil
  end

  private

  def login!
    write_sentence(['/login', "=name=#{@username}", "=password=#{@password}"])
    reply = read_sentence

    if reply.first == '!trap'
      raise ApiError, extract_message(reply)
    end

    ret = reply.find { |w| w.start_with?('=ret=') }
    return if ret.nil?

    challenge = ret.sub('=ret=', '')
    md5 = Digest::MD5.digest("\x00" + @password + [challenge].pack('H*'))
    response = '00' + md5.unpack1('H*')

    write_sentence(['/login', "=name=#{@username}", "=response=#{response}"])
    second_reply = read_sentence
    raise ApiError, extract_message(second_reply) if second_reply.first == '!trap'
  end

  def parse_attributes(sentence)
    sentence.drop(1).each_with_object({}) do |word, hash|
      next unless word.start_with?('=')
      key, value = word[1..].split('=', 2)
      hash[key] = value
    end
  end

  def extract_message(reply)
    msg_word = reply.find { |w| w.start_with?('=message=') }
    msg_word ? msg_word.sub('=message=', '') : reply.join(' ')
  end

  def read_all_replies
    sentences = []
    trap = nil
    loop do
      sentence = read_sentence
      next if sentence.empty?
      sentences << sentence
      raise ApiError, extract_message(sentence) if sentence.first == '!fatal'
      trap ||= sentence if sentence.first == '!trap'
      break if sentence.first == '!done'   # always drain to !done so the socket stays in sync
    end
    raise ApiError, extract_message(trap) if trap
    sentences
  end

  def write_sentence(words)
    words.each { |w| write_word(w) }
    write_word('')
  end

  def write_word(word)
    bytes = word.to_s.b
    @socket.write(encode_length(bytes.bytesize) + bytes)
  end

  def read_sentence
    words = []
    loop do
      word = read_word
      break if word.nil? || word.empty?
      words << word
    end
    words
  end

  def read_word
    length = read_length
    return nil if length.zero?
    read_exact(length).force_encoding(Encoding::UTF_8).scrub
  end

  def read_length
    b0 = read_exact(1).unpack1('C')

    if b0 & 0x80 == 0x00
      b0
    elsif b0 & 0xC0 == 0x80
      b1 = read_exact(1).unpack1('C')
      ((b0 & 0x3F) << 8) | b1
    elsif b0 & 0xE0 == 0xC0
      rest = read_exact(2).unpack('C2')
      ((b0 & 0x1F) << 16) | (rest[0] << 8) | rest[1]
    elsif b0 & 0xF0 == 0xE0
      rest = read_exact(3).unpack('C3')
      ((b0 & 0x0F) << 24) | (rest[0] << 16) | (rest[1] << 8) | rest[2]
    else
      read_exact(4).unpack1('N')
    end
  end

  def read_exact(n)
    buf = Timeout.timeout(@timeout) { @socket.read(n) }
    raise ApiError, 'Connection closed by router' if buf.nil? || buf.bytesize < n
    buf
  rescue Timeout::Error
    raise ApiError, 'Router took too long to respond'
  end

  def encode_length(len)
    if len < 0x80
      [len].pack('C')
    elsif len < 0x4000
      [len | 0x8000].pack('n')
    elsif len < 0x200000
      [(len | 0xC00000) >> 16, len & 0xFFFF].pack('Cn')
    elsif len < 0x10000000
      [(len | 0xE0000000) >> 24, (len >> 8) & 0xFFFF, len & 0xFF].pack('CnC')
    else
      [0xF0, len].pack('CN')
    end
  end
end