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
$LOAD_PATH.unshift File.dirname(__FILE__) + '/../lib'

require 'optparse'
require 'poprawa/gradebook'
require 'poprawa/report_generator'

def run_and_log(command, log)
  output = `#{command}`
  log.puts "#{command} --- #{$?.exitstatus}"
  log.puts output
  $?.exitstatus == 0
end

report_dir = "demo/progressReports"

options = {
  create: false,
  suppress_github: false,
  verbose: false,
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: gh_progress_report.rb [options]"

  opts.on("-c", "--[no-]create-report-directories", "Create report directories, if necessary") do |c|
    options[:create] = c
  end

  opts.on("-s", "--[no-]suppress-github", "Suppresses updates to github") do |s|
    options[:suppress] = s
  end

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end
parser.parse!

if ARGV.length == 0
  $stderr.puts "Must specify a config file."
  $stderr.puts parser.banner
  exit Poprawa::ExitValues::INVALID_PARAMETER
end

log = File.open("log.txt", "w+")

config_file_name = ARGV[0]
g = Poprawa::Gradebook.new(config_file_name, verbose: options[:verbose])

push_report = lambda do |student|
  directory =  File.dirname(g.config[:output_file].call(student.info[:github]))
  if (File.exist?(directory) && !options[:suppress])
    log.puts "*********************"
    puts student.info[:github]
    commands = ["git -C #{directory} add . --quiet", "git -C #{directory} commit -m 'Updated grade report' --quiet", "git -C #{directory} push --quiet"]
    success = commands.map {|command| run_and_log(command, log)}
    if success.include?(false)
      puts "Problem updating repo for #{student.full_name} (#{student.info[:github]})"
    end
  else
    puts "Skipping GitHub for #{student.full_name}" if options[:verbose]
  end
end

Poprawa::ReportGenerator.generate_reports(g, report_dir, after: push_report)
log.close