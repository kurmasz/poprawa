{
  gradebook_file: "#{File.dirname(__FILE__)}/../testWorkbook_noNil.xlsx",
  output_dir: OUTPUT_BASE = "#{File.dirname(__FILE__)}/../../output/poprawa-github-test/demo/progressReports",

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
    progress_thresholds: {
      meets_expectations: {a: 10, b: 9, c: 8, d: 6}, 
      progressing: {a: 11, b: 10, c: 9, d: 7},
      total: 11
    },
    hidden_info_columns: [:username, :github, :major],
  },
               {
    key: :homework,
    title: "Homework",
    short_name: "H",
    type: :empn,

    progress_thresholds: {
      meets_expectations: {a: 8, b: 6, c: 4, d: 2}, 
      progressing: {a: 9, b: 7, c: 5, d: 3},
      total: 10
    },
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
    last_saturday: "2023-4-29",
    meeting_days: "TR",
    skip_weeks: ["2023-3-5"],
    skip_days: ["2023-1-24"],
  },
}
