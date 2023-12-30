###################################################################################################
#
# demo_workbook_builder_config.rb
#
# This is an example config file for the workbook_builder script.
# 
# In practice we often use the same config file for both the workbook_builder and gh_progress_report 
# scripts. These scripts have considerable overlap in their configurations; therefore combining 
# the two configurations simplifies file management and avoids duplication. For 
# these examples, we use separate config files to (1) make it clear which items apply to which 
# script, and (2) so we can use different files for the .xlsx gradebook (so as not to accidentally
# overwrite our populated gradebook with a new, empty gradebook).
#
######################################################################################################

{
  # The name of the .xlsx file produced by workbook_builder 
  # Prefixing with File.dirname(__FILE__) makes the location of this file relative to this config 
  # file, rather than relative to the cwd of the workbook_builder process.
  gradebook_file: "#{File.dirname(__FILE__)}/demo_empty_workbook.xlsx",

  # The name of the .csv file containing user data. (See note above about prefixing.)
  roster_file: "#{File.dirname(__FILE__)}/demo_student_roster.csv",

  # info_sheet specifies the name of the worksheet within the workbook that contains student info.
  # info_sheet_config describes the columns in the info worksheet.
  #
  # The info worksheet contains two header columns: The first contains a "long" name that 
  # describes the data in that column. The second header row contains a "short" name 
  # that is used internally to access that data.
  #
  # To describe the info worksheet, use an array of Hashes containing *exactly one* key/value pair.
  # The key is the "short name" and the value is the "long name". The short name is used internally 
  # (including elsewhere in this config file) to identify columns. The long name is used for things
  # like reports.
  info_sheet_name: "info",
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
    { username: "Username" },
    { section: "Section" },
    { github: "GitHub" },
    { major: "Major" },
  ],

  # Specify how each column in an arbitrary .csv file should map to student info.
  # Each symbol must correspond to the "short name" of a column in the info_sheet_config above.
  # Important: The .csv is assumed to have a header row. This row is ignored. The values in the 
  # header row do not affect how the values are imported.
  #
  # To ignore a column in the .csv, just set the corresponding entry in the array to nil.
  #
  # Simply providing a "short name" results in the data being copied from the .csv to the 
  # worksheet. You can also provide a Hash that maps a short name to a lambda (or other 
  # callable object) that maps the .csv data to the value to be placed in the worksheet).
  # The example below converts the .csv's section number from a string to an integer.
  roster_config: [:lname, :fname, :username, {section: ->(value) {value.to_i}}],

  # Each category describes one worksheet in the workbook.
  #   * key:         the name of the worksheet (both programmatically and as displayed on the tabs)
  #   * title:       the full name displayed in reports
  #   * short_title:  an abbreviation occasionally used in reports
  #   * type:        the "type" of grade (letter, empn, etc.) Used to (1) style the display in
  #                  reports, and (2) calculate final grades.
  #   * hidden_info_columns: These columns are hidden in the workbook. (You can "unhide" them later
  #                  using Excel if you change your mind.)
  categories: [{
    key: :learningObjectives,
    title: "Learning Objectives",
    short_title: "LO",
    type: :empn,
    hidden_info_columns: [:username, :github, :major],
  },
  {
    key: :homework,
    title: "Homework",
    short_title: "H",
    type: :empn,
    hidden_info_columns: [:username, :major],
  },
  {
    key: :projects,
    title: "Projects",
    short_title: "P",
    type: :letter,
    hidden_info_columns: [:major],
  }],

  # Create an attendance worksheet, if desired.  (Just delete this item if you don't want one.)
  attendance: {
    first_sunday: "2023-1-8",   # The Sunday that begins the first week of class.
    last_saturday: "2023-4-29", # The Saturday that ends the last week of class.
    meeting_days: "TR",         # Days for which an attendance column should be created.
    skip_weeks: ["2023-3-5"],   # The Sunday that begins a week to skip entirely (e.g., Spring Break)
    skip_days: ["2023-1-24"],   # An individual day to skip (e.g., Memorial day)
  }
}
