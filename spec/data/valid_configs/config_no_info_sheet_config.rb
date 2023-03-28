{
  gradebook_file: "#{File.dirname(__FILE__)}/../../output/builder/testConfig.xlsx",
  roster_file: "#{File.dirname(__FILE__)}/../test_csv_student_roster.csv",
  roster_config: [:lname, :fname],

  info_sheet_name: "info",
  # missing info_sheet_config

  categories: [{
    key: :learningObjectives,
    title: "Learning Objectives",
    short_name: "LO",
    },
    {
    key: :homework,
    title: "Homework",
    short_name: "H",
    },
    {
    key: :projects,
    title: "Projects",
    short_name: "P",
  }]
}
