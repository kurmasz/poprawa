#####################################################################################
#
# ConfigLoader
#
# Loads a ruby-based config file. The specified file is expected to return
# a Ruby Hash
#
# (c) 2022 Zachary Kurmas
######################################################################################

module ConfigLoader
  #################################################################
  #
  # load_config
  #
  # Load the config from the named file
  #
  #################################################################
  def load_config(filename)
    b = {}.instance_eval { binding }

    begin
      content = File.read(filename)
    rescue Errno::ENOENT => e
      $stderr.puts "Config file \"#{filename}\" not found."
      exit ExitValues::INVALID_PARAMETER
    rescue => ioe
      $stderr.puts "Could not open config file \"#{filename}\" because"
      $stderr.puts ioe.message
      exit ExitValues::INVALID_PARAMETER
    end

    begin
      config = eval content, b, filename
    rescue SyntaxError => se
      $stderr.puts "Syntax error in config file:"
      $stderr.puts se.message
      exit ExitValues::INVALID_CONFIG
    rescue => e
      $stderr.puts "Exception thrown while evaluating config file:"
      $stderr.puts e.message
      $stderr.puts e.backtrace
      exit ExitValues::INVALID_CONFIG
    end

    unless config.is_a? Hash
      $stderr.puts "Config file must return a Ruby Hash."
      exit ExitValues::INVALID_CONFIG
    end

    config
  end # load_config
end # module
