#####################################################################################
#
# Report Generator
#
#
# (c) 2022 Zachary Kurmas
#####################################################################################

class ReportGenerator
  MARK_ORDER = ["e", "m", "p", "x"]

  # TODO  This probably now belongs somewhere else.  But, I'm not sure where...
  def self.highest_mark(mark_list)
    marks = mark_list.split("").map { |m| MARK_ORDER.include?(m) ? m : "x" }
    marks.sort { |a, b| MARK_ORDER.find_index(a) <=> MARK_ORDER.find_index(b) }.first.to_sym
  end

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
  def self.generate_reports(gradebook, students = gradebook.students, before: nil, after: nil)
    students.select { |s| s.active? }.each do |student|
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

    out.puts <<HERE
    Note:  This is a draft of the progress report generator.  This version only shows the
    marks I have for each graded item.  Future reports will contain more detail.
HERE

    gradebook.categories.each do |category|
      out.puts "## #{category[:title]}"
      out.puts "|#{category[:title]}|Grade|Late Days|"
      out.puts "|------|-------|-------|"

      category[:assignment_names].each do |key, value|
        marks = format_marks(student.get_mark(category[:key], key))
        late_days = student.get_late_days(category[:key], key)

        out.printf "|%s (%s)|%s|%s|\n", value, key, marks, late_days
      end # each item

      generate_mark_breakdown(student, category, out)
      current_grade = gradebook.calc_grade(student, category: category[:key])      
      out.printf "\nCurrent grade:  #{current_grade}\n" if current_grade
    end # each category

    generate_legend(out)

    out.close
  end

  #
  # format_marks
  #
  # returns a formatted string of marks with the highest grade bolded
  #
  def self.format_marks(marks)
    return if marks.nil?

    mark_values = { "e" => 3, "m" => 2, "p" => 1 }
    highest = 0
    highest_index = -1

    marks = marks.split("")

    marks.each_with_index do |mark, index|
      next if !mark_values.key?(mark)

      if mark_values[mark] >= highest
        highest = mark_values[mark]
        highest_index = index
      end
    end

    marks[highest_index] = "**#{marks[highest_index]}**" if highest_index > -1

    return marks.join(" ")
  end

  #
  # generate_mark_breakdown
  #
  def self.generate_mark_breakdown(student, category, out)
    mark_count = { e: 0, m: 0, p: 0, x: 0 }

    category[:assignment_names].each do |key, value|
      marks = student.get_mark(category[:key], key)
      next if marks.nil?

      mark_count[highest_mark(marks)] += 1
    end

    out.puts
    out.puts "|E|M|P|X|"
    out.puts "|------|-------|-------|-------|"
    out.puts "|#{mark_count[:e]}|#{mark_count[:m]}|#{mark_count[:p]}|#{mark_count[:x]}|"
    out.puts
    out.puts "#{mark_count[:e] + mark_count[:m]} at 'm' or better."
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
