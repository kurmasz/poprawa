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
#
###################################################################################################
{

  # The name of the .xlsx file produced by workbook_builder 
  gradebook_file: "#{File.dirname(__FILE__)}/demo_empty_workbook.xlsx",

  # The name of the .csv file containing user data.
  roster_file: "#{File.dirname(__FILE__)}/demo_student_roster.csv",

  # The contents of an arbitrary .csv student roster file.
  # (Each symbol must correspond to the "short name" of a column in the info_sheet_config below)
  roster_config: [:lname, :fname, :username, :section],

  # If your .csv file was exported from the BB Classic gradebook, then simply set 
  # roster_config: :bb_classic,

  # Each info_sheet_config key is the "short name" for that column (the symbol used internally to
  # reference the data.  The value is the "long name" is the text displayed in the top row of each
  # worksheet and in reports.)
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
  #   key: the name of the worksheet (both programmatically and as displayed on the tabs)
  #   hidden_info_columns: These columns are hidden in the workbook. (You can "unhide" them later
  #                  using Excel if you change your mind.)
  categories: [{
    key: :learningObjectives,
    hidden_info_columns: [:username, :github, :major],
  },
  {
    key: :homework,
    hidden_info_columns: [:username, :major],
  },
  {
    key: :projects,
    hidden_info_columns: [:major],
  }],

  # Creates an attendance worksheet. Items below identify (1) the first and 
  # last days of class, and (2) any breaks (either single-days or full weeks)
  attendance: {
    first_sunday: "2023-1-8",
    last_saturday: "2023-4-29",
    meeting_days: "TR", # (Use "R" for Thursday, "S" for Saturday, and "U" for Sunday)
    skip_weeks: ["2023-3-5"], # Spring Break
    skip_days: ["2023-1-24"], # Martin Luther King Day.
  },
}
