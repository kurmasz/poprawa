#####################################################################################
#
# ConfigLoader
#
# Loads a ruby-based config file. The specified file is expected to return
# a Ruby Hash
#
# (c) 2022 Zachary Kurmas
######################################################################################
require "poprawa/exit_values"

module Poprawa
  module ConfigLoader
    #################################################################
    #
    # load_config
    #
    # Load the config from the named file
    #
    #################################################################
    def self.load_config(filename)
      b = {}.instance_eval { binding }

      if filename.strip.start_with?("{")
        content = filename
      else
        begin
          content = File.read(filename)
        rescue Errno::ENOENT => e
          $stderr.puts "Config file \"#{filename}\" not found."
          exit Poprawa::ExitValues::INVALID_PARAMETER
        rescue => ioe
          $stderr.puts "Could not open config file \"#{filename}\" because"
          $stderr.puts ioe.message
          exit Poprawa::ExitValues::INVALID_PARAMETER
        end
      end

      begin
        config = eval content, b, filename
      rescue SyntaxError => se
        $stderr.puts "Syntax error in config file:"
        $stderr.puts se.message
        exit Poprawa::ExitValues::INVALID_CONFIG
      rescue => e
        $stderr.puts "Exception thrown while evaluating config file:"
        $stderr.puts e.message
        $stderr.puts e.backtrace
        exit Poprawa::ExitValues::INVALID_CONFIG
      end

      unless config.is_a? Hash
        $stderr.puts "Config file must return a Ruby Hash."
        exit Poprawa::ExitValues::INVALID_CONFIG
      end

      config
    end # load_config
  end # module ConfigLoader
end # module Poprawa
