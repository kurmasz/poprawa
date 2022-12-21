{
  gradebook_file: "#{File.dirname(__FILE__)}/test-output/testWorkbookBuilder.xlsx",
  roster_file: "#{File.dirname(__FILE__)}/testStudentInfo.csv",

  info_sheet_name: "info",
  info_sheet_config: [
    {lname: 'Last Name'},
    {fname: 'First Name'},
    {username: 'Username'},
    {section: 'Section'},
    {github: 'GitHub'},
    {major: 'Major'}
  ],

  categories: [{
    key: :learningObjectives,
    title: "Learning Objectives",
    short_name: "LO",
    type: :empn,
    hidden_info_columns: [:username,:github, :major]
  },
  {
    key: :homework,
    title: "Homework",
    short_name: "H",
    type: :empn,
    hidden_info_columns: [:username, :major]
  },
  {
    key: :projects,
    title: 'Projects',
    short_name: 'P',
    type: :letter,
    hidden_info_columns: [:major]
  }
]
}