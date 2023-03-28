{
  gradebook_file: "#{File.dirname(__FILE__)}/../../output/builder/testConfig.xlsx",
  roster_file: "#{File.dirname(__FILE__)}/../test_csv_student_roster.csv",
  roster_config: [:lname, :fname],

  info_sheet_name: "info",
  info_sheet_config: [
    { lname: "Last Name" },
    { fname: "First Name" },
  ],

  categories: [] # empty categories
}
