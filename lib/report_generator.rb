#####################################################################################
#
# Report Generator
#
#
# (c) 2022 Zachary Kurmas
#####################################################################################

class ReportGenerator

  #
  # generate_reports
  #
  # before: is a lambda that generates the output stream to which 
  # this student should be printed.
  #
  # after: is a lambda that does any necessary post-processing 
  # (e.g., delivering the report to the target location)
  #
  # The "pre-processing" code can alternatively be passed as a block
  # instead of a lambda.
  def self.generate_reports(gradebook, students=gradebook.students, before: nil, after: nil)
    students.select{ |s| s.active?}.each do |student|
      out = before.nil? ? yield(student) : before.(student)
      generate_report(student, gradebook, out) unless out.nil?
      after.(student) unless after.nil?
    end
  end 

  # 
  # generate_report
  #
  # generate a report for one student
  #
  def self.generate_report(student, gradebook, out)
    out.puts "# Progress Report for #{student.full_name}"
    out.puts

    out.puts <<HERE
    Note:  This is a draft of the progress report generator.  This version only shows the
    marks I have for each graded item.  Future reports will contain more detail.
HERE


    gradebook.categories.each do |category|
      out.puts "## #{category[:title]}"
      out.puts
      out.puts "|#{category[:title]}|Grade|Late Days|"
      out.puts "|------|-------|-------|"

      category[:assignment_names].each do |key, value|
        mark = format_marks(student.get_mark(category[:key], key))
        late_days = student.get_late_days(key)

        out.printf "|%s (%s)|%s|%s|\n", value, key, mark, late_days.nil? ? 0 : late_days
      end # each item
      out.puts
      out.puts
    end # each category

    generate_legend(out)

    out.close  
  end

  #
  # format_grades
  #
  # returns a formatted string of grades with the highest grade bolded
  #
  def self.format_marks(marks)
    return if marks.nil?
    
    mark_values = {"e" => 3, "m" => 2, "p" => 1}
    highest = 0
    highest_index = -1
    
    marks = marks.split('')

    marks.each_with_index do |mark, index|
      next if !mark_values.key?(mark)

      if mark_values[mark] >= highest
        highest = mark_values[mark]
        highest_index = index
      end
    end

    marks[highest_index] = "**#{marks[highest_index]}**" if highest_index > -1

    return marks.join(' ')
  end

  def self.generate_legend(out)

      out.puts
      out.puts "## Legend "
      out.puts "* `e`: Exceeds expectations"
      out.puts "* `m`: Meets expectations"
      out.puts "* `p`: Progressing"
      out.puts "* `x`: Not Yet"
      out.puts "* `.`: Missing"
      out.puts "* `d`: Demonstrated but not yet graded"
      out.puts "* `r`: Received but not yet graded"
      out.puts "* `?`: Received; Grading in progress"
      out.puts "* `!`: Error in gradesheet"
  end
end
