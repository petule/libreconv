require "libreconv/version"
require "uri"
require "net/http"
require "tmpdir"
require "spoon"

module Libreconv

  def self.convert(source, target, soffice_command = nil, convert_to = nil)
    Converter.new(source, target, soffice_command, convert_to).convert
  end

  class Converter
    attr_accessor :soffice_command

    def initialize(source, target, soffice_command = nil, convert_to = nil)
      @source = source
      @target = target
      @target_path = Dir.tmpdir
      @soffice_command = soffice_command
      @convert_to = convert_to || "pdf"
      determine_soffice_command
      check_source_type

      unless @soffice_command && File.exists?(@soffice_command)
        raise IOError, "Can't find Libreoffice or Openoffice executable."
      end
    end

    def convert
      orig_stdout = $stdout.clone
      $stdout.reopen File.new('/dev/null', 'w')
      Rails.logger.debug  " #{@soffice_command} --invisible --headless --convert-to #{@convert_to} --outdir #{@target_path} #{@source}"
      system " #{@soffice_command} --invisible --headless --convert-to #{@convert_to} --outdir #{@target_path} #{@source}"
      $stdout.reopen orig_stdout
      target_tmp_file = "#{@target_path}/#{File.basename(@source, ".*")}.#{File.basename(@convert_to, ":*")}"
      FileUtils.cp target_tmp_file, @target
     # system "  rm #{target_tmp_file}"
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
      return if File.exists?(@source) && !File.directory?(@source) #file
      return if URI(@source).scheme == "http" && Net::HTTP.get_response(URI(@source)).is_a?(Net::HTTPSuccess) #http
      return if URI(@source).scheme == "https" && Net::HTTP.get_response(URI(@source)).is_a?(Net::HTTPSuccess) #https
      raise IOError, "Source (#{@source}) is neither a file nor an URL."
    end
  end
end
