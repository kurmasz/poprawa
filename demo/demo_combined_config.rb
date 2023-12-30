###################################################################################################
#
# demo_combined_config.rb
#
# We find it most convenient to use the same configuration file for both workbook_builder and
# gh_report_generator. Many items are used by both scripts. Both scripts also ignore items that
# are unneeded.
#
######################################################################################################

{
  gradebook_file: "#{File.dirname(__FILE__)}/demo_workbook_from_combined_config.xlsx",
  roster_file: "#{File.dirname(__FILE__)}/demo_student_roster.csv",
  output_dir: "#{File.dirname(__FILE__)}/progressReports",

  info_sheet_name: "info",
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
    { username: "Username" },
    { section: "Section" },
    { github: "GitHub" },
    { major: "Major" },
  ],

  roster_config: [:lname, :fname, :username, {section: ->(value) {value.to_i}}],

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

  attendance: {
    first_sunday: "2023-1-8",   # The Sunday that begins the first week of class.
    last_saturday: "2023-4-29", # The Saturday that ends the last week of class.
    meeting_days: "TR",         # Days for which an attendance column should be created.
    skip_weeks: ["2023-3-5"],   # The Sunday that begins a week to skip entirely (e.g., Spring Break)
    skip_days: ["2023-1-24"],   # An individual day to skip (e.g., Memorial day)
  }
}
