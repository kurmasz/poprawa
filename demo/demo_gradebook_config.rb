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
  gradebook_file: "#{File.dirname(__FILE__)}/demo_empty_workbook.xlsx",

  # The name of the .csv file containing user data.
  roster_file: "#{File.dirname(__FILE__)}/testStudentInfo.csv",

  # The contents of an arbitrary .csv student roster file.
  # (Each symbol must correspond to the "short name" of a column in the info_sheet_config below)
  roster_config: [:lname, :fname, :username, :section]

  # If your .csv file was exported from the BB Classic gradebook, then simply set 
  # roster_config to :bb_classic
  # roster_config: :bb_classic

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