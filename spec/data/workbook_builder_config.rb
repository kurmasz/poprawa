#  OUTPUT_BASE = "#{File.dirname(__FILE__)}/../spec/output/poprawa_test/tw_clean"

{
  gradebook_file: "#{File.dirname(__FILE__)}/../output/builder/testWorkbook.xlsx",
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
