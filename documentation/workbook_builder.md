# Workbook Builder 

The `workbook_builder` script generates a correctly-formatted Excel Workbook (`.xlsx` file) for used with 
`gh_progress_report` and other Poprawa-based scripts.

To run `workbook_builder` you need 
1. A Ruby config file that that describes the gradebook structure (e.g., the different assignment categories).
2. A `.csv` file that contains student info (e.g., names, sections, etc.).  

Then, simply run `workbook_builder name_of_config.rb`

## Workbook Builder Config 

Here is a sample config file:

```ruby
{
  gradebook_file: "#{File.dirname(__FILE__)}/demo_empty_workbook.xlsx",
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
  # ...
  ],

  attendance: {
    first_sunday: "2023-1-8",
    last_saturday: "2023-4-29",
    meeting_days: "TR",
    skip_weeks: ["2023-3-5"],
    skip_days: ["2023-1-24"],
  },
}
```


