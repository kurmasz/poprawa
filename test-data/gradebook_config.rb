OUTPUT_BASE = "#{File.dirname(__FILE__)}/progressReports"
{
  gradebook_file: "#{File.dirname(__FILE__)}/demo_grades.xlsx",
  output_file: lambda {|github_dir| "#{OUTPUT_BASE}/#{github_dir}/README.md"  },
  info_sheet_name: "info",
  categories: [{
    key: :learningObjectives,
    title: "Learning Objectives",
    short_name: "LO",
  },
               {
    key: :homework,
    title: "Homework",
    short_name: "H",
  }],
}
