#!/usr/bin/env ruby

require 'readline'
require 'fileutils'
require 'json'
require 'time'
require 'terminal-table'

class VFSFramework
  COMMANDS = %w[use set show search exploit back help exit]

  def initialize(mod_base = nil)
    @mod_base = mod_base || File.expand_path("./modules", __dir__)
    @active_mod = nil
    @mod_name = nil
    @options = { "RHOSTS" => nil, "RPORT" => "32776", "LHOST" => "127.0.0.1", "THREADS" => "10" }
    
    if File.exist?(File.expand_path("./lib/moduleach.rb", __dir__))
      require_relative 'lib/moduleach'
      VFS_ModuleAch.init(@mod_base)
    end
    setup_autocomplete
  end

  def setup_autocomplete
    Readline.completion_proc = proc { |str| COMMANDS.grep(/^#{Regexp.escape(str)}/) }
  end

  # banner
  def banner
    system("clear")
    puts "\e[31m\e[1m"
    puts "      \\ "
    puts "      /                                 />"
    puts "     \\__+_____________________/\\/\\___/ /|"
    puts "      ()______________________      / /|/\\"
    puts "                  /0 0  ---- |----    /---\\ "
    puts "                  |0 o 0 ----|| - \\ --|      \\        MODULE: #{@active_mod ? 1 : 0}"
    puts "                   \\0_0/____/ |    |  |\\      \\      EXPLOIT: #{@active_mod ? 1 : 0}"
    puts "Bang! Bang!                    \\__/__/  |      \\      PAYLOAD: 0"
    puts "VFS Framework - VIOLENTFUCKSOCIETY      |       \\       "
    puts "---------------------------------------|        \\"
    puts "\e[36m    [ v0.9| Gate: ACTIVE | Vault: Local ]\e[0m\n\n"
    puts " by:eliot00 (@eliot00) - https://github.com/eliot00-byte\n"
  end

  #help command
  def handle_help
    table = Terminal::Table.new(headings: ['Command', 'Description', 'Usage'])
    table << ['use', 'Load a module from the vault', 'use <path>']
    table << ['set', 'Configure session variables', 'set <KEY> <VAL>']
    table << ['show', 'Display options or modules', 'show <options|modules>']
    table << ['search', 'Search modules by name/CVE', 'search <query>']
    table << ['exploit', 'Trigger memory injection', 'exploit']
    table << ['back', 'Unload current module', 'back']
    table << ['exit', 'Shutdown framework', 'exit']
    puts table
  end

  # seatch modules
  def search_modules(query = "")
    table = Terminal::Table.new(headings: ['Path', 'Module Name', 'Target System'])
    Dir.glob("#{@mod_base}/**/*.rb").each do |path|
      rel_path = path.gsub(@mod_base + "/", "").gsub(".rb", "")
      if query.empty? || rel_path.include?(query)
        begin
          content = File.read(path)
          m_name = content[/@name\s+=\s+"(.+)"/, 1] || File.basename(path)
          m_target = content[/@target\s+=\s+"(.+)"/, 1] || "Generic"
          table << [rel_path, m_name, m_target]
        rescue
          table << [rel_path, "Reading Error", "N/A"]
        end
      end
    end
    puts table
  end

  def dispatch(input)
    parts = input.split(/\s+/)
    cmd = parts.shift.to_s.downcase
    return if cmd.empty?

    case cmd
    when "use"     
      when "use"
  target_module = parts[0]
  module_path = File.join(@mod_base, "#{target_module}.rb")
  
  if File.exist?(module_path)
    @mod_name = target_module
    VFS_UI.success("Module loaded: #{@mod_name}")
  else
    puts "\e[31m[-] Error: Module '#{target_module}' not found in vault.\e[0m"
    @mod_name = nil # Reset nếu nạp sai
  end
    when "set"     then @options[parts[0].upcase] = parts[1]
    when "show"    then (parts[0] == "options" ? handle_show_options : search_modules(""))
    when "search"  then search_modules(parts[0].to_s)
    when "help"    then handle_help
    when "exploit" then puts "[*] Triggering VFS Engine..."
      if @mod_name
        puts "[*] Triggering VFS Engine..."
        if defined?(VFS_Engine) && VFS_Engine.ready?
           VFS_Engine.vfs_raw_gate(1 ^ 0xAA, 1, 0, 0, 0, 0) 
           puts "[+] Stealth Gate: Decoded and Executed."
        else
           puts "[-] Engine Error: Core logic not found."
        end
      else
        puts "[-] Error: No module selected."
      end
    when "back"    then @active_mod = nil; @mod_name = nil; banner
      puts "[*] Returned to main console."
      if stopclear
        @active_mod = nil
        @mod_name = nil
        banner

    when "exit"    then exit(0)
    end
  end

  def handle_show_options
    table = Terminal::Table.new(headings: ['Name', 'Setting', 'Required'])
    @options.each { |k,v| table << [k, v || "NOT SET", "yes"] }
    puts table
  end

  def start
    banner
    loop do
      ctx = @mod_name ? "(\e[31m#{@mod_name}\e[0m)" : ""
      input = Readline.readline("\e[1mvfsconsole\e[0m#{ctx} > ", true)
      break if input.nil?
      dispatch(input.strip)
    end
  end
end

# run the console if executed directly
if __FILE__ == $0
  VFSFramework.new.start
end
