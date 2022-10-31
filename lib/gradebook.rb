#####################################################################################
#
# Gradebook
#
# Holds the data from an Excel-based gradebook
#
# (c) 2022 Zachary Kurmas
######################################################################################

require_relative "./gradebook_loader"

class Gradebook

  # TODO Write a method to validate the format of the config
  # (e.g., is categories an array, does it have the necessary keys, etc.)
  def self.cis371_config
    {
      info_sheet_name: "info",
      categories: [{
        key: :learningObjectives,
        title: "Learning Objectives",
        short_name: "LO",
      },
                   {
        key: :homework,
        title: "Homework",
        short_name: "HW",
      }],
    }
  end

  def self.cis343_config
    {
      info_sheet_name: "info",
      categories: [{
        key: :learningObjectives,
        title: "Learning Objectives",
        short_name: "LO",
      },
                   {
        key: :projects,
        title: "Projects",
        short_name: "P",
      }],
    }
  end

  def self.default_config
    self.cis371_config
  end

  #
  # self.load_config
  #
  # Load the config hash from the named file
  #
  def self.load_config(filename)
    b = {}.instance_eval { binding }
    begin
      eval File.read(filename), b, filename   
    rescue Errno::ENOENT => e
      puts "Config file #{filename} not found."
      exit
    rescue => e
      puts "Could not open config file"
      puts e.message
      exit
    end
  end


  attr_reader :students, :config

  def initialize(config_in, verbose: false)

    if (config_in.is_a? String)
      config = Gradebook.load_config(config_in)
    elsif (config_in.is_a? Hash)
      config = config_in
    else 
      puts "Error! Parameter to Gradebook#initialize must either be a String (filename) or a Hash"
    end

    filename = config[:gradebook_file]
    puts "Processing gradebook #{filename}" if verbose

    # !!! load modifies the config hash
    GradebookLoader.load(filename, config, verbose: verbose) do |students|
      @students = students.freeze
      @config = config.freeze
    end
    freeze
  end

  def categories
    @config[:categories]
  end
end
