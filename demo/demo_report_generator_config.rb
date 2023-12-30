###################################################################################################
#
# demo_report_generator_config.rb
#
# This is an example config file for the report_generator script.
# 
# In practice, we often use the same config file both the workbook_builder and gh_progress_report 
# scripts. These scripts have considerable overlap in their configurations; therefore combining 
# the two configurations simplifies file management and avoids duplication. For 
# these examples, we use separate config files to (1) make it clear which items apply to which 
# script, and (2) so we can use different files for the .xlsx gradebook (so as not to accidentally
# overwrite our populated gradebook with a new, empty gradebook).
#
######################################################################################################

{
  # The name of the .xlsx file containing the grades.
  # Prefixing with File.dirname(__FILE__) makes the location of this file relative to this config 
  # file, rather than relative to the cwd of the workbook_builder process.
  gradebook_file: "#{File.dirname(__FILE__)}/demo_populated_workbook.xlsx",

  # The directory containing the progress reports. (Each progress report is a directory
  # containing a git repo.)
  output_dir: "#{File.dirname(__FILE__)}/progressReports",

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

  # Each category describes one worksheet in the workbook.
  #   * key:         the name of the worksheet (both programmatically and as displayed on the tabs)
  #   * title:       the full name displayed in reports
  #   "TODO" Are we still using "short_name"? 
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
}
