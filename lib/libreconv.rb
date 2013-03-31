require "libreconv/version"
require "uri"
require "net/http"

module Libreconv

  def self.convert(source, target, soffice_command = nil)
    Converter.new(source, target, soffice_command).convert
  end

  class Converter
    attr_accessor :soffice_command

    def initialize(source, target_path, soffice_command = nil)
      @source = source
      @target_path = target_path
      @soffice_command = soffice_command 
      determine_soffice_command
      check_source_type
      
      unless @soffice_command && File.exists?(@soffice_command) 
        raise IOError, "Can't find Libreoffice or Openoffice executable."
      end
    end

    def convert
      cmd = "#{@soffice_command} --headless --convert-to pdf #{@source} -outdir #{@target_path}"
      pid = Process.spawn(cmd, [:out, :err] => "/dev/null")
      Process.waitpid(pid)
    end

    private

    def determine_soffice_command
      unless @soffice_command
        @soffice_command ||= which("soffice")
        @soffice_command ||= which("soffice.bin")
      end
    end

    def which(cmd)
      exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
      ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each do |ext|
          exe = File.join(path, "#{cmd}#{ext}")
          return exe if File.executable? exe
        end
      end
    
      return nil
    end

    def check_source_type
      is_file = File.exists?(@source) && !File.directory?(@source)
      is_http = URI(@source).scheme == "http" && Net::HTTP.get_response(URI(@source)).is_a?(Net::HTTPSuccess)
      is_https = URI(@source).scheme == "https" && Net::HTTP.get_response(URI(@source)).is_a?(Net::HTTPSuccess)    
      
      raise IOError, "Source (#{@source}) is neither a file nor an URL." unless is_file || is_http || is_https
    end
  end
end