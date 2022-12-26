#! /usr/bin/env ruby
#####################################################################################
#
# workbook_builder
#
# Builds a new Excel workbook for tracking grades.
#
# Takes as input a ruby file that returns a hash with the following items:
# {
#    roster_file:       name of .csv file that contains student data
#    gradebook_file:    name of .xlsx file to be generated
#    info_sheet_name:   name to be given to the worksheet that will hold student info
#    info_sheet_config: array specifying columns in the info sheet. See details below.
#    categories:        array containing the details of each grading category.
# }
#
# The info_sheet_config is an array.  Each item of the array is a hash containing exactly
# one key.  The key is the Ruby symbol used to identify that category. The value is the
# full name of the category that will appear in grade reports.
#
# Each category is a hash.  The following items are required for the workbook builder
#    key:                 the Ruby symbol used to identify this category
#    title:               the "full text" title used in reports
#    hidden_info_columns: an array listing the user info columns to be hidden
#                         (The values in this array should be symbols that appear in
#                          the info_sheet_config)
#
# (c) 2022 Zachary Kurmas
######################################################################################

require "csv"
require "date"
require "optparse"
require "rubyXL"
require "rubyXL/convenience_methods"

COLUMNS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

DAY_ABBREV = {
  u: 0,
  m: 1,
  t: 2,
  w: 3,
  r: 4,
  f: 5,
  s: 6,
}

module ExitValues  
  INVALID_PARAMETER = 4
end

#
# Sample configuration
#
sample_config = {

  # input .csv file containing user information. (Using __FILE__ means that this
  # input file is expected to be placed in the same directory as this config file.)
  roster_file: "#{File.dirname(__FILE__)}/studentInfo_343w23.csv",

  # output spreadsheet file.
  gradebook_file: "#{File.dirname(__FILE__)}/cis343_W23.xlsx",

  # name of the student info worksheet in the resulting Excel workbook.
  info_sheet_name: "info",

  # The list of columns to be added to the student info sheet.
  # (Notice that each column is described by a Hash with exactly one key.)
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
    { username: "Username" },
    { section: "Section" },
    { github: "GitHub" },
    { major: "Major" },
  ],

  # Descriptions of the various grading categories.
  # Not all info here will be used by the workbook builder.  Some fields
  # are used by the grade report generator.
  categories: [
    {
      key: :learningObjectives,
      title: "Learning Objectives",
      short_name: "LO",
      type: :empn,

      # The elements of this array must be keys in the info_sheet_config above.
      hidden_info_columns: [:username, :github, :major],
    },
    {
      key: :homework,
      title: "Homework",
      short_name: "H",
      type: :empn,
      hidden_info_columns: [:username, :major],
    },
    {
      key: :projects,
      title: "Projects",
      short_name: "P",
      type: :letter,
      hidden_info_columns: [:major],
    },
  ],
}

#################################################################
#
# parse_blackboard_userinfo
#
# Read the data from a Blackboard-exported .csv
#
# Specifically, this method maps each non-header row in the CSV
# to the following keys:
#  :lname
#  :fname
#  :username
#  <Column D is not used>
#  :section
#
# The section column is expected to be of this form, where the middle
# component is the section number: GVCIS343.01.202320
#
#################################################################
def parse_blackboard_userinfo(input_file)
  students = []

  # TODO: Also handle header row and make sure the expected headers are present.
  CSV.foreach(input_file, headers: :first_row, encoding: "bom|utf-8") do |row|
    row[4] =~ /[^.]+\.([^.]+)\.[^.]+/

    student = {
      :lname => row[0],
      :fname => row[1],
      :username => row[2],
      :section => $1.to_i,
    }

    student.each do |key, value|
      if value.nil? || value.to_s.strip.empty?
        puts "WARNING: Field #{key} in row \"#{row}\" is empty."
      end
    end
    # p student
    students << student
  end
  students
end

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
    eval File.read(filename), b, filename
  rescue Errno::ENOENT => e
    $stderr.puts "Config file \"#{filename}\" not found."
    exit ExitValues::INVALID_PARAMETER
  rescue SyntaxError => se
    $stderr.puts "Syntax error in config file:"
    $stderr.puts se.message
    exit ExitValues::INVALID_PARAMETER
  rescue SystemCallError => ioe
    $stderr.puts "Could not open config file \"#{filename}\" because"
    $stderr.puts ioe.message
    exit ExitValues::INVALID_PARAMETER
  rescue => e
    $stderr.puts "Exception thrown while evaluating config file:"
    $stderr.puts e.message
    $stderr.puts e.backtrace
    exit ExitValues::INVALID_PARAMETER
  end
end

#################################################################
#
# add_protected_xf
#
# Add a new XF (object that describes style) to the workbook.
# (This style object enables protection.)
#################################################################
def add_protected_xf(workbook)
  new_xf = workbook.cell_xfs.first.dup
  new_xf.protection = RubyXL::Protection.new(
    locked: true,
    hidden: false,
  )
  new_xf_id = workbook.register_new_xf(new_xf)
end

#################################################################
#
# add_unprotected_xf
#
# Add a new XF (object that describes style) to the workbook.
# (This style object _disables_ protection.)
#################################################################
def add_unprotected_xf(workbook)
  new_xf = workbook.cell_xfs.first.dup
  new_xf.protection = RubyXL::Protection.new(
    locked: false,
    hidden: false,
  )
  new_xf_id = workbook.register_new_xf(new_xf)
end

#################################################################
#
# header_keys
#
# Generate an array containing only the keys from the Hashes
# in the info_sheet_config.  (Each Hash in headers must contain
# exactly one key.)
#################################################################
def header_keys(headers)
  headers.map do |item|
    if (item.keys.length != 1)
      puts "Invalid info sheet config. Item has multiple keys: #{item.inspect}"
      exit
    end
    item.keys.first
  end
end

#################################################################
#
# add_headers
#
# Add the headers to the specified worksheet.  headers should be
# an array containing Hashes with one key only.  The value will
# be placed in row 1 and the key will be placed in row 2.
#################################################################
def add_headers(sheet, headers)
  header_keys(headers).each_with_index do |header_key, index|
    sheet.add_cell(0, index, headers[index][header_key])
    sheet.add_cell(1, index, header_key.to_s)
  end
end

#################################################################
#
# add_gradesheet
#
# Add a worksheet for the given category.
#
#################################################################
def add_gradesheet(workbook, category, config, protected_xf_id, unprotected_xf_id, section: nil)
  base_name = category[:key].to_s
  name = section.nil? ? base_name : "#{base_name}_s#{section}"

  info_sheet = workbook[config[:info_sheet_name]]
  sheet = workbook.add_worksheet(name)
  num_info_columns = config[:info_sheet_config].count

  # Add references to the info sheet
  info_sheet.each_with_index do |row, row_index|
    # (three dots "..." in a range excludes ending value)
    (0...num_info_columns).each do |col_index|
      cell = sheet.add_cell(row_index, col_index, "", formula = "=#{config[:info_sheet_name]}!#{COLUMNS[col_index]}#{row_index + 1}")

      # Protect these references so they can't be modified.
      # (Any changes should be made on the info sheet only.)
      cell.style_index = protected_xf_id

      # TODO:  Hide rows belonging to other sections
    end
  end

  # Hide unneeded columns.
  keys = header_keys(config[:info_sheet_config])
  (0...num_info_columns).each do |col_index|
    if (category[:hidden_info_columns].include?(keys[col_index]))
      sheet.cols.get_range(col_index).hidden = true
    end
  end

  # Create a ColumnRange to describe "all" columns.
  # Specify that the columns in this range should be unprotected by default.
  # (Individual cells may override this protection.)
  range = RubyXL::ColumnRange.new
  range.min = 1
  range.max = 16384
  range.width = 10.83203125
  range.style_index = unprotected_xf_id
  sheet.cols << range   # add this range to the set of ColumnRanges for this sheet.

  # Enable protection for this sheet.
  sheet.sheet_protection = RubyXL::WorksheetProtection.new(
    sheet: true,
    objects: true,
    scenarios: true,
    format_cells: false,
    format_columns: false,
    insert_columns: false,
    delete_columns: false,
    insert_rows: false,
    delete_rows: false,
  )

  # Add a freeze
  worksheetviews = RubyXL::WorksheetViews.new
  pane = RubyXL::Pane.new(:top_left_cell => RubyXL::Reference.new(2, num_info_columns),
                          :x_split => num_info_columns, :y_split => 2, :state => "frozenSplit")
  worksheetviews << RubyXL::WorksheetView.new(:pane => pane)
  sheet.sheet_views = worksheetviews

  sheet
end

#################################################################
#
# add_attendance_sheet
#
#################################################################
def add_attendance_sheet(workbook, config, protected_xf_id, unprotected_xf_id)
  category = {
    key: :attendance,
    title: "Attendance",
    type: :attendance,
    hidden_info_columns: [:username, :github, :major],
  }
  sheet = add_gradesheet(workbook, category, config, protected_xf_id, unprotected_xf_id)

  start_date = Date.parse(config[:attendance][:first_sunday])
  end_date = Date.parse(config[:attendance][:last_saturday])

  meeting_days = config[:attendance][:meeting_days].to_s.downcase.chars.map { |day_char| "umtwrfs".index(day_char) }
  skip_weeks = config[:attendance][:skip_weeks].map { |week| Date.parse(week.to_s)}
  skip_days = config[:attendance][:skip_days].map { |day| Date.parse(day.to_s)}

  left = false
  col_index = config[:info_sheet_config].count
  start_date.upto(end_date) do |current_date|

    # Skip days that class doesn't meet.
    next unless meeting_days.include?(current_date.wday)

    # Skip any days explicitly listed in config.
    next if skip_days.include?(current_date)

    # Skip any weeks explicitly listed in config.
    prev_sunday = current_date - current_date.wday
    next if skip_weeks.include?(prev_sunday)

    c = sheet.add_cell(1, col_index)
    c.set_number_format("d-mmm-yy")
    c.change_contents(current_date)

    top = false
    (2...sheet.sheet_data.rows.size).each do |row_index|
      sheet.add_cell(row_index, col_index)
      sheet.sheet_data[row_index][col_index].change_border(:left, "thin") if left # skip the first column
      sheet.sheet_data[row_index][col_index].change_border(:top, "thin") if top  # skip the first data row
      top = true
    end

    left = true
    col_index += 1
  end
end

#################################################################
#
# main
#
#################################################################

options = {}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: workbook_builder.rb config_file [options]"

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end

  opts.on("-oFILE", "--output=FILE", "Output file") do |name|
    options[:output] = name
  end
end

parser.parse!

if ARGV.length < 1
  $stderr.puts "Must specify a config file."
  $stderr.puts parser.banner
  exit ExitValues::INVALID_PARAMETER
end
config_file = ARGV[0]

config = load_config(config_file)

if options.has_key?(:output)
  output_file = options[:output]
else
  output_file = config[:gradebook_file]
end

if (File.exists?(output_file))
  puts "Output file #{output_file} exists.  Overwrite?"
  answer = $stdin.gets.downcase.strip
  if answer == "y" || answer == "yes"
    puts "Overwriting."
  else
    puts "Exiting without overwriting."
    exit
  end
end

students = parse_blackboard_userinfo(config[:roster_file])

# https://www.rubydoc.info/gems/rubyXL/1.1.2
workbook = RubyXL::Workbook.new

protected_xf_id = add_protected_xf(workbook)
unprotected_xf_id = add_unprotected_xf(workbook)

#
# Add info sheet:
#

# Workbooks appear to be created with a single worksheet named 'Sheet 1'
if workbook.worksheets.size == 1
  info_sheet = workbook.worksheets.first
  info_sheet.sheet_name = config[:info_sheet_name]
else
  info_sheet = workbook.add_worksheet(config[:info_sheet_name])
end

add_headers(info_sheet, config[:info_sheet_config])
students.each_with_index do |student, index|
  adj_index = index + 2
  header_keys(config[:info_sheet_config]).each_with_index do |header_key, col_index|
    info_sheet.add_cell(adj_index, col_index, student[header_key])
  end
end

#
# Add category sheets
#

config[:categories].each do |category|
  add_gradesheet(workbook, category, config, protected_xf_id, unprotected_xf_id)
end

add_attendance_sheet(workbook, config, protected_xf_id, unprotected_xf_id)

#
# Write the new workbook.
#
workbook.write(output_file)
