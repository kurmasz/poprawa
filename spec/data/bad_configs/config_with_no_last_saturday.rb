{
  gradebook_file: "#{File.dirname(__FILE__)}/../testConfig.xlsx",
  roster_file: "#{File.dirname(__FILE__)}/../test_csv_student_roster.csv",
  roster_config: [:lname, :fname, :username, :section],

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

  attendance_sheet_name: "attendance",
  attendance: {
    first_sunday: "2023-1-8",
    meeting_days: "TR",
    skip_weeks: ["2023-3-5"],
    skip_days: ["2023-1-24"],
  },
}
