#! /usr/bin/env ruby

# TODO: Remove me before production
# QQQ1 Temporary hack to run scripts in development
$LOAD_PATH.unshift File.dirname(__FILE__) + "/../lib"

#####################################################################################
#
# workbook_builder
#
# Builds a new Excel workbook for tracking grades.
#
# Specifically, the generated Excel Workbook will contain
#  * an "information" worksheet
#  * a worksheet for each category, and
#  * an attendance worksheet
#
# The first several columns of each category and attendance worksheet will contain
# references to the user data in the information worksheet. These cells will be
# protected (i.e., "locked") to prevent accidental modification. (If you want to
# modify user data, do it on the information worksheet.)
#
# See demo/demo_workbook_builder_config.rb for a sample config file and an
# explanation of the available fields.
#
# (c) 2022 Zachary Kurmas
######################################################################################

require "csv"
require "date"
require "optparse"
require "rubyXL"
require "rubyXL/convenience_methods"
require "poprawa/config_loader"
require "gv_config"

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

default_config = {
  info_sheet_name: "info",
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
  ],
}

#####################################################################
#
# verify_kv_pair
#
# Verify that pair is a Hash that has exactly one key-value pair
#####################################################################
def verify_kv_pair(pair, description)

  unless pair.is_a?(Hash)
    $stderr.puts "Invalid #{description}. Hash expected but #{pair.class} found: #{pair.inspect}"
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  if pair.keys.length == 0
    $stderr.puts "Invalid #{description}. Item may not be empty."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  if pair.keys.length != 1
    $stderr.puts "Invalid #{description}. Item has multiple keys: #{pair.inspect}"
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  return pair.to_a.first
end

#######################################################################
#
# roster_config_kv
#
# The roster_config array can contain, either
#   1. Just a symbol, or
#   2. A Hash with one key/value pair mapping a symbol onto a lambda.
#
# Verify that the item is formatted properly and return the resulting
# key and value.
#
########################################################################
def roster_config_kv(item, value_in = nil, call_lambda: false, row: nil)
  if item.is_a?(Hash)
    # Verify that item is just a single key-value pair
    key, raw_value = verify_kv_pair(item, "roster config")

    unless raw_value.respond_to? :call
      $stderr.puts "Invalid roster config: Value for #{key} must be a lambda. (#{item.inspect})"
      exit Poprawa::ExitValues::INVALID_CONFIG
    end

    # The user-provided lambda can take either one or two parameters.
    # This code below sends only the number expected. (In other words,
    # it makes sure that the program doesn't crash if the user writes a
    # lambda that takes only one parameter.)

    args = [value_in, row]
    expected_args = args[0...raw_value.arity]
    value = call_lambda ? raw_value.call(*expected_args) : value_in
  else
    key = item
    value = value_in
  end
  return [key, value]
end

#################################################################
#
# verify_config
#
# Verify that the config file contains all of the necessary
# information.
#################################################################
def verify_config(config, options)
  # verify that output file exists
  if not options.has_key?(:output)
    if config[:gradebook_file].nil?
      $stderr.puts "Config must include a gradebook_file item."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end
  end

  # verify that roster config exists
  unless config.has_key?(:roster_config)
    $stderr.puts "Config must include a :roster_config item specifying the format of the .csv file."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  if config[:roster_config].nil?
    $stderr.puts "Roster config cannot be nil."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  # verify that roster config is valid
  unless config[:roster_config].kind_of?(Array)
    $stderr.puts "Roster config of type #{config[:roster_config].class} not recognized."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  # verify that info_sheet_name is valid
  # **We don't test for the existence of info_sheet_name because there is a default
  if not config[:info_sheet_name].kind_of?(String)
    $stderr.puts ":info_sheet_name must be a string."
    exit Poprawa::ExitValues::INVALID_CONFIG
  elsif config[:info_sheet_name].empty?
    $stderr.puts ":info_sheet_name cannot be empty."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  # verify that info_sheet_config is valid
  # **We don't test for the existence of info_sheet_config because there is a default
  if config[:info_sheet_config].empty?
    $stderr.puts "Config must include an :info_sheet_config item that is not empty."
    exit Poprawa::ExitValues::INVALID_CONFIG
  elsif not config[:info_sheet_config].kind_of?(Array)
    $stderr.puts ":info_sheet_config item must be an array."
    exit Poprawa::ExitValues::INVALID_CONFIG
  elsif not config[:info_sheet_config].all? { |info| info.kind_of?(Hash) }
    $stderr.puts "All items in :info_sheet_config array must be Hashes."
    exit Poprawa::ExitValues::INVALID_CONFIG
  elsif config[:info_sheet_config].any? { |info| info.empty? }
    $stderr.puts "No items in :info_sheet_config array can be empty."
    exit Poprawa::ExitValues::INVALID_CONFIG
  elsif config[:info_sheet_config].any? { |info| info.size > 1 }
    $stderr.puts "No Hash in :info_sheet_config can contain more than one item."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  # verify that categories is valid
  if config.has_key?(:categories)
    if config[:categories].empty?
      $stderr.puts "Config must include a :categories item that is not empty."
      exit Poprawa::ExitValues::INVALID_CONFIG
    elsif not config[:categories].kind_of?(Array)
      $stderr.puts ":categories item must be an array."
      exit Poprawa::ExitValues::INVALID_CONFIG
    elsif not config[:categories].all? { |category| category.kind_of?(Hash) }
      $stderr.puts "All items in :categories array must be Hashes."
      exit Poprawa::ExitValues::INVALID_CONFIG
    elsif config[:categories].any? { |category| category.empty? }
      $stderr.puts "No items in :categories array can be empty."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end
  else
    $stderr.puts "Config must include a :categories item."
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  # verify that each category has a key
  config[:categories].each do |category|
    unless category.has_key?(:key)
      $stderr.puts "Config must include a :key for each category."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end
  end

  # TODO Test this
  # if attendance exists, verify that it contains a first sunday, last saturday, and meeting_days item
  if config.has_key?(:attendance)
    unless config[:attendance].has_key?(:first_sunday)
      $stderr.puts "Attendance config must include a value for :first_sunday."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end

    unless config[:attendance].has_key?(:last_saturday)
      $stderr.puts "Attendance config must include a value for :last_saturday."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end

    unless config[:attendance].has_key?(:meeting_days)
      $stderr.puts "Attendance config must include a value for :meeting_days."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end
  end
end

#####################################################################
#
# parse_csv_userinfo
#
# Read the student info data from an arbitrary .csv
#
# input_file: The name of the .csv file
# columns:    The symbol for the corresponding column in the info
#             table (or nil if this .csv column should be ignored)
#
# For example, if columns is [:lname, :fname, :username, :section],
# then the data from the first column will be stored in the student
# object with a key of :lname, the second in :fname, and so on.
# In other words, the keys in this array refer to the keys used
# internally in this app *not* the values that appear in the CSV file's
# header row.
#
# Note: .csv file is assumed to have a header row.  However, we
# still require the config file to specify the .csv column to
# info table column mapping in the config file so that (1) users
# need not edit the header row if it is generated automatically by
# an LMS or other export, and (2) users can specify that a column
# in the .csv file not be included in the info table without
# removing the header information from the .csv file itself.
#
#####################################################################
def parse_csv_userinfo(input_file, roster_file_config)
  students = []

  # TODO: make the header row optional QQQ2
  CSV.foreach(input_file, headers: :first_row, encoding: "bom|utf-8") do |row|
    student = {}
    roster_file_config.each_with_index do |column_config, index|
      next if column_config.nil?
      key, value = roster_config_kv(column_config, row[index], call_lambda: true, row: row)
      student[key.to_sym] = value
    end

    student.each do |key, value|
      if value.nil? || value.to_s.strip.empty?
        puts "WARNING: Field #{key} in row \"#{row.to_s.chomp}\" is empty."
      end
    end
    students << student
  end
  students
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
      # TODO Is there a test for this?
      $stderr.puts "Invalid info sheet config. Item has multiple keys: #{item.inspect}"
      exit Poprawa::ExitValues::INVALID_CONFIG
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

#########################################################################################################
#
# add_gradesheet
#
# Add a worksheet for the given category.
#
#########################################################################################################
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
      cell = sheet.add_cell(row_index, col_index, "", formula = "#{config[:info_sheet_name]}!#{COLUMNS[col_index]}#{row_index + 1}")

      # Protect these references so they can't be modified.
      # (Any changes should be made on the info sheet only.)
      cell.style_index = protected_xf_id

      # TODO:  Hide rows belonging to other sections
    end
  end

  # Hide unneeded columns.
  keys = header_keys(config[:info_sheet_config])
  (0...num_info_columns).each do |col_index|
    if not category[:hidden_info_columns].nil?
      if category[:hidden_info_columns].include?(keys[col_index])
        sheet.cols.get_range(col_index).hidden = true
      end
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
  worksheet_views = RubyXL::WorksheetViews.new
  pane = RubyXL::Pane.new(:top_left_cell => RubyXL::Reference.new(2, num_info_columns),
                          :x_split => num_info_columns, :y_split => 2, :state => "frozenSplit")
  worksheet_views << RubyXL::WorksheetView.new(:pane => pane)
  sheet.sheet_views = worksheet_views
  sheet
end

#########################################################################################################
#
# add_attendance_sheet
#
#########################################################################################################
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
  skip_weeks = config[:attendance][:skip_weeks]&.map { |week| Date.parse(week.to_s) } if config[:attendance].has_key?(:skip_weeks)
  skip_days = config[:attendance][:skip_days]&.map { |day| Date.parse(day.to_s) } if config[:attendance].has_key?(:skip_days)

  # Add borders to the user info data.
  (0...config[:info_sheet_config].count).each do |col_index|
    (3...sheet.sheet_data.rows.size).each do |row_index|
      sheet.sheet_data[row_index][col_index].change_border(:top, "thin")
    end
  end

  col_index = config[:info_sheet_config].count
  start_date.upto(end_date) do |current_date|

    # Skip days that class doesn't meet.
    next unless meeting_days.include?(current_date.wday)

    # Skip any days explicitly listed in config.
    next if skip_days && skip_days.include?(current_date)

    # Skip any weeks explicitly listed in config.
    prev_sunday = current_date - current_date.wday
    next if skip_weeks && skip_weeks.include?(prev_sunday)

    c = sheet.add_cell(1, col_index)
    c.set_number_format("d-mmm-yy")
    c.change_contents(current_date)

    top = false
    (2...sheet.sheet_data.rows.size).each do |row_index|
      sheet.add_cell(row_index, col_index)
      sheet.sheet_data[row_index][col_index].change_border(:left, "thin")
      sheet.sheet_data[row_index][col_index].change_border(:top, "thin") if top  # skip the first data row
      top = true
    end

    col_index += 1
  end
end

#########################################################################################################
#
# load_student_info
#
#########################################################################################################

def load_student_info(config)
  unless config[:roster_config].kind_of?(Array)
    # This should have already been checked.
    $stderr.puts "roster_config must be an array"
    exit Poprawa::ExitValues::INVALID_CONFIG
  end

  config[:roster_config].each do |column_config|
    next if column_config.nil?
    column_name, _ = roster_config_kv(column_config)
    info_sheet_keys = config[:info_sheet_config].map { |kv_pair| kv_pair.keys.first }

    unless column_name.respond_to?(:to_sym)
      $stderr.puts "Roster config keys must be symbols. (#{column_name} is of type #{column_name.class}.)"
      exit Poprawa::ExitValues::INVALID_CONFIG
    end

    unless info_sheet_keys.include?(column_name.to_sym)
      $stderr.puts "Key #{column_name} found in roster_config but not in info_sheet_config."
      exit Poprawa::ExitValues::INVALID_CONFIG
    end
  end
  students = parse_csv_userinfo(config[:roster_file], config[:roster_config])
end

#########################################################################################################
#
# main
#
#########################################################################################################

options = {
  merge: [],
  force: false,
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: workbook_builder.rb config_file [options]"

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit Poprawa::ExitValues::SUCCESS
  end

  opts.on("-oFILE", "--output=FILE", "Output file") do |name|
    options[:output] = name
  end

  opts.on("-f", "--force", "Force overwrite") do |f|
    options[:force] = f
  end

  # Used primarily for testing. (So we don't end up with an unmanageable
  # number of config files that only differ by a line or two.)
  opts.on("-mFILE", "--merge=FILE", "Merge additional config file") do |name|
    options[:merge] << name
  end
end

parser.parse!

if ARGV.length < 1
  $stderr.puts "Must specify a config file."
  $stderr.puts parser.banner
  exit Poprawa::ExitValues::INVALID_PARAMETER
end
config_file = ARGV[0]

main_config = Poprawa::ConfigLoader::load_config(config_file)

# Merge config_file over default_config
config = default_config.merge(main_config)

# Merge additional config files.  (Values in subsequent files override
# values from previous files.)
config = options[:merge].inject(config) do |partial, merge_file|
  merge_config = Poprawa::ConfigLoader::load_config(merge_file)
  partial.merge(merge_config)
end

verify_config(config, options)

#
# Set up output file
#

if options.has_key?(:output)
  output_file = options[:output]
else
  output_file = config[:gradebook_file]
end

if File.exists?(output_file)
  if options[:force]
    puts "Overwriting output file by --force."
  else
    puts "Output file #{output_file} exists.  Overwrite?"
    answer = $stdin.gets.downcase.strip
    if answer == "y" || answer == "yes"
      puts "Overwriting."
    else
      puts "Exiting without overwriting."
      exit
    end # if answer
  end # if --force

  # Make a "backup" of the file being overwritten
  FileUtils.cp(output_file, "#{output_file}~")
end

students = load_student_info(config)

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
    info_sheet.add_cell(adj_index, col_index, student[header_key]) if (student.has_key?(header_key))
  end
end

#
# Add category sheets
#

config[:categories].each do |category|
  # generate category key if missing
  unless category.has_key?(:key)
    category[:key] = category[:title].gsub(/\s+/, "_").downcase.to_sym
  end

  unless category.has_key?(:short_title)
    category[:short_title] = category[:title].split.map(&:chr).join.upcase
  end

  add_gradesheet(workbook, category, config, protected_xf_id, unprotected_xf_id)
end

add_attendance_sheet(workbook, config, protected_xf_id, unprotected_xf_id) if config.has_key?(:attendance)

#
# Write the new workbook.
#
workbook.write(output_file)
$stdout.puts "Workbook written to #{output_file}"
