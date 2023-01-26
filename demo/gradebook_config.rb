grade_info = {
  learningObjectives: {
     total: 13
  },
  homework: {
    total: 13,
  }
}

{
  gradebook_file: "#{File.dirname(__FILE__)}/demo_grades.xlsx",

  # This is a separate git repo so that the commits generated by the demo don't add
  # noise to the git history.
  output_dir: "#{File.dirname(__FILE__)}/../spec/output/poprawa-github-test/demo/progressReports",
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
    type: :empn
  },
               {
    key: :homework,
    title: "Homework",
    short_name: "H",
    type: :empn
  }],

  # very dumb algorithm as proof of concept.
  # I also don't like the name "calc_grade"
  calc_grade: lambda do |student, category: nil, final_grade: true|
    if (category.nil? && !final_grade) 
      puts "If final_grade is false, you must either specify a category"
      exit 5
    end
    
    # puts "Calculating #{final_grade ? 'final' : category} grade for #{student.full_name}"

    categories = category.nil? ? [:learningObjectives, :homework] : [category]

    m_or_better = 0
    categories.each do |cat|
      m_or_better += student.get_marks(cat).select { |m| m =~ /m|e/}.count
    end

    m_or_better >= 4 * categories.length ? 'A' : 'B'
  end
}
