#! /usr/bin/env ruby
#####################################################################################
#
# gh_progress_report
#
# Builds a Markdown progress report for each student based on an Excel gradesheet
# then pushes that report to a private GitHub repo.
#
# (c) 2022 Zachary Kurmas
######################################################################################

# --porcelain   https://github.com/ruby-git/ruby-git

# TODO: Remove me before production
# Temporary hack to run scripts in development
$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"

require 'git'
require 'logger'
require "optparse"
require "poprawa/gradebook"
require "poprawa/report_generator"

default_config = {}

#
# update_repo
#
# add/commit/push updated grade report to student repo
#
def update_repo(working_dir, student) 
  git_dir = working_dir

  # loop through file system until git root is found
  while !File.exist?("#{git_dir}/.git")
    git_dir = File.dirname(git_dir)

    if git_dir == '/'
      puts "Unable to locate git repo for #{student.info[:github]}"
      return
    end
  end

  begin
    g = Git.open("#{git_dir}", :raise => true)
    if g.status.changed.any?
      g.add
      g.commit('Updated grade report')
      g.push('origin', g.current_branch)
    else
      $stderr.puts "No changes for #{student.full_name}"
    end
  rescue Git::GitExecuteError => e
    puts "Problem updating repo for #{student.full_name}, (#{student.info[:github]})"
    puts "error: #{e.message}"
  end
end

options = {
  debug_config: false,
  create: false,
  suppress_github: false,
  verbose: false,
  merge: [],
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: gh_progress_report.rb [options]"

  opts.on("-c", "--[no-]create-report-directories", "Create report directories, if necessary") do |c|
    options[:create] = c
  end

  opts.on("-s", "--[no-]suppress-github", "Suppresses updates to github") do |s|
    options[:suppress] = s
  end

  opts.on("-o", "--output DIR", "Base directory for output") do |o|
    options[:output_dir] = o  
  end

  # Used primarily for testing. (So we don't end up with an unmanageable
  # number of config files that only differ by a line or two.)
  opts.on("-mFILE", "--merge=FILE", "Merge additional config file") do |name|
    options[:merge] << name
  end

  # TODO: Remove this after confirming that Merge works
  opts.on("--override VALUE", "Override a config value") do |o|

    # TODO Write tests
    unless o =~ /([^:]+):(.*)/
      $stderr.puts "--override parameter \"#{o}\" is incorrectly formatted."
      exit Poprawa::ExitValues::INVALID_PARAMETER
    end
    puts "Overriding #{$1} with #{$2}"
    options[:overrides][$1.to_sym] = $2
  end

  opts.on("--debug-config=[KEY]", "Display config values and exit") do |dc|
    options[:debug_config] = dc
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end
parser.parse!()

if ARGV.length == 0
  $stderr.puts "Must specify a config file."
  $stderr.puts parser.banner
  exit Poprawa::ExitValues::INVALID_PARAMETER
end

log = File.open("log.txt", "w+")

config_file_name = ARGV[0]
main_config = Poprawa::ConfigLoader::load_config(config_file_name)

# Merge config_file over default_config
config = default_config.merge(main_config)

# Merge additional config files.  (Values in subsequent files override
# values from previous files.)
config = options[:merge].inject(config) do |partial, merge_file|
  merge_config = Poprawa::ConfigLoader::load_config(merge_file)
  partial.merge(merge_config)
end

# TODO: Remove this after we know merge works
# options[:overrides].each { |key, value| config[key] = value }

# Override the output directory (if specified)
if (options.has_key?(:output_dir)) 
  config[:output_dir] = options[:output_dir]
end

if (options[:debug_config])
  key = options[:debug_config].to_sym
  if config.has_key?(key)
    puts "Config key #{key} has value \"#{config[key]}\""
  else
    puts "Config does not contain key #{key}"
  end
  exit Poprawa::ExitValues::SUCCESS
elsif options[:debug_config].nil?
  p config
  exit Poprawa::ExitValues::SUCCESS
end

# warn about nonexistent/invalid base output directory
# TODO Test me
output_dir = config[:output_dir]
if !File.exist?(output_dir)
  $stderr.puts "Output directory #{output_dir} doesn't exist."
  exit Poprawa::ExitValues::INVALID_PARAMETER
end

if !File.directory?(output_dir)
  $stderr.puts "#{output_dir} is not a directory."
  exit Poprawa::ExitValues::INVALID_PARAMETER
end

if !File.directory?(output_dir)
  $stderr.puts "Output directory #{output_dir} is not writable."
  exit Poprawa::ExitValues::INVALID_PARAMETER
end


g = Poprawa::Gradebook.new(config, verbose: options[:verbose])

push_report = lambda do |student|
  directory = "#{output_dir}/#{student.info[:github]}"
  if (File.exist?(directory) && !options[:suppress])
    log.puts "*********************."
    log.puts "Updating repo for #{student.full_name} (#{student.info[:github]})"
    update_repo(directory, student)
  else
    puts "Skipping GitHub for #{student.full_name}" if options[:verbose]
  end
end

Poprawa::ReportGenerator.generate_reports(g, create_dir: options[:create], after: push_report)
log.close
