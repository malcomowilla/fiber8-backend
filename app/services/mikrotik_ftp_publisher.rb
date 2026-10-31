require "net/ftp"
require "tempfile"

class MikrotikFtpPublisher
  def initialize(ip:, username:, password:, html_directory: nil, port: 21)
    @ip, @username, @password, @port = ip, username, password, port
    @html_directory = html_directory.to_s.strip.gsub(%r{\A/+|/+\z}, "").presence
  end

  # Returns the full remote path the file was written to.
  def upload_login(html)
    tmp = Tempfile.new(["login", ".html"])
    tmp.write(html)
    tmp.close

    ftp = Net::FTP.new
    ftp.passive = true
    ftp.open_timeout = 10
    ftp.read_timeout = 20
    ftp.connect(@ip, @port)
    ftp.login(@username, @password)

    ensure_path(ftp, @html_directory || detect_directory(ftp))
    ftp.putbinaryfile(tmp.path, "login.html")
    "#{ftp.pwd}/login.html"
  ensure
    ftp&.close unless ftp&.closed?
    tmp&.unlink
  end

  private

  # Router has a flash disk -> flash/hotspot, otherwise plain hotspot.
  def detect_directory(ftp)
    root = ftp.nlst.map { |n| n.to_s.delete_prefix("/") }
    root.include?("flash") ? "flash/hotspot" : "hotspot"
  rescue Net::FTPError
    "hotspot"
  end

  def ensure_path(ftp, path)
    ftp.chdir("/")
    path.split("/").each do |segment|
      begin
        ftp.chdir(segment)
      rescue Net::FTPPermError
        ftp.mkdir(segment)
        ftp.chdir(segment)
      end
    end
  end
end