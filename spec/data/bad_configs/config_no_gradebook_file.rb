{
  # missing gradebook file  
  roster_file: "#{File.dirname(__FILE__)}/../test_csv_student_roster.csv",
    roster_config: [:lname, :fname],
  
    info_sheet_name: "info",
    info_sheet_config: [
      { lname: "Last Name" },
      { fname: "First Name" },
    ],
  
    categories: [{
      key: :learningObjectives,
      title: "Learning Objectives",
      short_title: "LO",
      },
      {
      key: :homework,
      title: "Homework",
      short_title: "H",
      },
      {
      key: :projects,
      title: "Projects",
      short_title: "P",
    }]
  }