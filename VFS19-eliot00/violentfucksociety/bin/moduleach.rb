#!/usr/bin/env ruby
require 'readline'
require 'fileutils'
require 'json'
require 'time'
require_relative 'lib/moduleach'

module VFS_UI
  C = { g: "\e[32m", r: "\e[31m", b: "\e[34m", y: "\e[33m", x: "\e[0m", bold: "\e[1m" }
  def self.status(m); puts "#{C[:b]}[*] #{m}#{C[:x]}"; end
  def self.success(m); puts "#{C[:g]}[+] #{m}#{C[:x]}"; end
  def self.error(m); puts "#{C[:r]}[-] ERROR: #{m}#{C[:x]}"; end
end

class VFSFramework
  def initialize
    @active_mod = nil
    @mod_name = nil
    @options = { "TARGET" => nil, "THREADS" => "10" }
    @mod_base = File.expand_path("modules", __dir__)
    VFS_ModuleAch.init(@mod_base)
    setup_autocomplete
  end

  def setup_autocomplete
    Readline.completion_proc = proc do |str|
      (VFS_ModuleAch.all_modules + %w[use set show exploit exit help]).grep(/^#{Regexp.escape(str)}/)
    end
  end

  def save_report(results)
    return if results.nil? || @mod_name.nil?
    
    date_str = Time.now.strftime("%Y-%m-%d")
    report_dir = File.join("reports", @mod_name, date_str)
    FileUtils.mkdir_p(report_dir)

    # File: 14-30-05_report.json
    file_name = "#{Time.now.strftime("%H-%M-%S")}_report.json"
    full_path = File.join(report_dir, file_name)

    File.open(full_path, "w") { |f| f.write(JSON.pretty_generate({target: @options["TARGET"], data: results})) }
    VFS_UI.success("Report saved: #{full_path}")
  end

  def dispatch(input)
    parts = input.split(/\s+/)
    cmd = parts.shift.to_s.downcase
    return if cmd.empty?

    case cmd
    when "use"
      path = VFS_ModuleAch.find_path(parts[0])
      if path
        Object.send(:remove_const, :VFSModule) if Object.const_defined?(:VFSModule)
        load path
        @active_mod = VFSModule.new
        @mod_name = parts[0].include?("/") ? parts[0] : path.split('modules/').last.gsub('.rb', '')
        VFS_UI.success("Using module: #{@mod_name}")
      else
        VFS_UI.error("Module not found.")
      end
    when "set"
      @options[parts[0].upcase] = parts[1]
      VFS_UI.status("#{parts[0].upcase} => #{parts[1]}")
    when "show"
      parts[0] == "options" ? (puts @options) : (puts VFS_ModuleAch.all_modules)
    when "exploit"
      if @active_mod
        res = @active_mod.run(@options)
        save_report(res)
      else
        VFS_UI.error("No module loaded.")
      end
    when "exit" then exit(0)
    end
  end

  def start
    system("clear")
    puts "VFS ARCHITECT ENGINE ENABLED\n"
    loop do
      prompt = @mod_name ? "vfs(#{@mod_name}) > " : "vfs > "
      input = Readline.readline(prompt, true)
      break if input.nil?
      dispatch(input.strip)
    end
  end
end

VFSFramework.new.start