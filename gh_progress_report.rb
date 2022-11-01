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

require 'optparse'
require_relative "lib/gradebook"
require_relative "lib/report_generator"

options = {
  create: false,
  suppress_github: false,
  verbose: false,
}

OptionParser.new do |opts|
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
end.parse!

if ARGV.length == 0
  $stderr.puts "Usage: gh_progress_report config_file"
  exit
end

config_file_name = ARGV[0]
g = Gradebook.new(config_file_name, verbose: options[:verbose])

setup_report = lambda do |student|
  puts "Processing #{student.full_name}" if options[:verbose]
  filename = g.config[:output_file].call(student.info[:github])

  dirname = File.dirname(filename)
  if (options[:create] && !File.exist?(dirname))
    puts "Creating report directory for #{student.full_name} --- #{dirname}"
    Dir.mkdir(dirname)
  end

  begin
    File.open(filename, "w+")
  rescue Errno::ENOENT => e
    puts "#{student.full_name}" unless options[:verbose]
    puts "\tUnable to open output file #{filename} (Make sure the directory exists.)"
    nil
  rescue => e
    puts "#{student.full_name}" unless options[:verbose]
    puts "\tUnable to open output file: #{e.message}"  
  end # end begin/rescue
end # setup_report

push_report = lambda do |student|
  directory =  File.dirname(g.config[:output_file].call(student.info[:github]))
  if (File.exist?(directory) && !options[:suppress])
    `(cd #{directory}; git add .; git commit -m "Updated grade report"  --porcelain; git push --porcelain)` unless directory.nil?
  end
end


ReportGenerator.generate_reports(g, before: setup_report, after: push_report)