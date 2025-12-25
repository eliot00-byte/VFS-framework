# @name = "VFS Advanced Account Hunter"
# @target = "Username / Digital Alias"
# @description = "Multi-threaded stealth discovery with response body validation."

require 'net/http'
require 'uri'
require 'thread'

class VFSModule
  def run(options)
    username = options['TARGET']
    if username.nil? || username.empty?
      VFS_UI.error("Architecture Error: TARGET (username) is not set.")
      return
    end

    VFS_UI.status("Executing Global Identity Trace: #{VFS_UI::C[:y]}#{username}#{VFS_UI::C[:x]}")
    
    # define target platforms
    platforms = {
      "GitHub"    => { url: "https://github.com/{}", error: "Not Found" },
      "Twitter"   => { url: "https://twitter.com/{}", error: "does not exist" },
      "Instagram" => { url: "https://www.instagram.com/{}/", error: "Page Not Found" },
      "Reddit"    => { url: "https://www.reddit.com/user/{}", error: "not found" },
      "Pinterest" => { url: "https://www.pinterest.com/{}/", error: "404" },
      "TikTok"    => { url: "https://www.tiktok.com/@{}", error: "Couldn't find" },
      "Steam"     => { url: "https://steamcommunity.com/id/{}", error: "could not be found" }
    }

    results = []
    threads = []
    mutex = Mutex.new

    VFS_UI.info("Spawning high-speed workers...")

    platforms.each do |name, config|
      threads << Thread.new do
        uri = URI.parse(config[:url].gsub("{}", username))
        begin
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == 'https'
          http.open_timeout = 5
          
          request = Net::HTTP::Get.new(uri.request_uri)
          # Use a real browser User-Agent
          request["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
          
          response = http.request(request)
          
          # Real OSINT Logic: Check status 200 AND make sure error text isn't in the body
          if response.code == "200" && !response.body.include?(config[:error])
            mutex.synchronize do 
              VFS_UI.success("Hit Confirmed: #{name}")
              results << [name, "ACTIVE", uri.to_s]
            end
          end
        rescue => e
          # Fail silently for connection timeouts
        end
      end
    end

    threads.each(&:join)

    puts "\n"
    if results.empty?
      VFS_UI.info("No traces found for entity '#{username}'.")
    else
      table = Terminal::Table.new(headings: ['Platform', 'Status', 'Target URL'], rows: results)
      puts table
    end
    VFS_UI.success("Identity mapping completed.")
  end
end