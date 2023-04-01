###################################################################################################
#
# demo_workbook_builder_config.rb
#
# This is an example config file for the workbook_builder script.
# 
# In practice we often use the same config file both the workbook_builder and gh_progress_report 
# scripts. These scripts have considerable overlap in their configurations; therefore combining 
# the two configurations simplifies file management and avoids duplication. For 
# these examples, we use separate config files to (1) make it clear which items apply to which 
# script, and (2) so we can use different files for the .xlsx gradebook (so as not to accidentally
# overwrite our populated gradebook with a new, empty gradebook).
{

  # The name of the .xlsx file produced by workbook_builder 
  # Prefixing with File.dirname(__FILE__) makes the location of this file relative to this config 
  # file, rather than relative to the cwd of the workbook_builder process (which is usually the 
  # desired behavior))
  gradebook_file: "#{File.dirname(__FILE__)}/demo_empty_workbook.xlsx",

  # The name of the .csv file containing user data.  (See note above about prefixing.)
  roster_file: "#{File.dirname(__FILE__)}/testStudentInfo.csv",

  # info_sheet specifies the name of the Worksheet within the Workbook that contains student info.
  #
  # This info worksheet contains two header columns. The first contains a "Long" name that 
  # fully describes the data in that column.  THe second header row contains a "short" name 
  # that is used internally to access that data.
  #
  # To describe the info worksheet, use an array of Hashes containing *exactly one* key/value pair.
  # The key is the "short name" and the value is the "long name".  
  info_sheet_name: "info",
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
    { username: "Username" },
    { section: "Section" },
    { github: "GitHub" },
    { major: "Major" },
  ],

  # The contents of an arbitrary .csv student roster file.
  # (Each symbol must correspond to the "short name" of a column in the info_sheet_config below)
  roster_config: [:lname, :fname, :username, :section]

  # If your .csv file was exported from the BB Classic gradebook, then simply set 
  # roster_config to :bb_classic
  # roster_config: :bb_classic




  # Each category describes one worksheet in the workbook.
  #   * key:         the name of the worksheet (both programmatically and as displayed on the tabs)
  #   * title:       the full name displayed in reports
  #   "TODO" Are we still using "short_name"? 
  #   * short_name:  an abbreviation occasionally used in reports
  #   * type:        the "type" of grade (letter, empn, etc.) Used to (1) style the display in
  #                  reports, and (2) calculate final grades.
  #   * hidden_info_columns: These columns are hidden in the workbook. (You can "unhide" them later
  #                  using Excel if you change your mind.)
  categories: [{
    key: :learningObjectives,
    title: "Learning Objectives",
    short_name: "LO",
    type: :empn,
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
  }],

  attendance: {
    first_sunday: "2023-1-8",
    last_saturday: "2023-4-29",
    meeting_days: "TR",
    skip_weeks: ["2023-3-5"],
    skip_days: ["2023-1-24"],
  },
}
