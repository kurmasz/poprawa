# This file can be used as a config for both the workbook_builder and gh_progress_report scripts.
# The two scripts have considerable overlap in their configurations, so combining the two scripts 
# simplifies the process and avoids duplication.
{

  # The name of the .xlsx file produced by workbook_builder and read by gh_progress_report
  gradebook_file: "#{File.dirname(__FILE__)}/demo_empty_workbook.xlsx",

  # The name of the .csv file containing user data.
  roster_file: "#{File.dirname(__FILE__)}/testStudentInfo.csv",

  info_sheet_name: "info",
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
    { username: "Username" },
    { section: "Section" },
    { github: "GitHub" },
    { major: "Major" },
  ],

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
