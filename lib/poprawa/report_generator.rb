#####################################################################################
#
# Report Generator
#
#
# (c) 2022 Zachary Kurmas
#####################################################################################

module Poprawa
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
    # after: is a lambda that does any necessary post-processing
    # (e.g., delivering the report to the target location)
    #
    def self.generate_reports(gradebook, students = gradebook.students, report_dir, after: nil)
      students.select { |s| s.active? }.each do |student|
        out = setup_student_dir(student, gradebook)
        generate_report(student, gradebook, out, report_dir) unless out.nil?
        after.(student) unless after.nil?
      end
    end

    #
    # setup_student_dir
    #
    # loads a student directory and creates an output file
    # 
    def self.setup_student_dir(student, g)
      filename = g.config[:output_file].call(student.info[:github])

      dirname = File.dirname(filename)
      # warn about nonexistent directory
      if !File.exist?(dirname)
        puts "Report directory doesn't exist for #{student.full_name} --- #{dirname}"
        return nil
      end

      begin
        File.open(filename, "w+")
      rescue Errno::ENOENT => e
        puts "#{student.full_name}"
        puts "\tUnable to open output file #{filename} (Make sure the directory exists.)"
        return nil
      rescue => e
        puts "#{student.full_name}"
        puts "\tUnable to open output file: #{e.message}"  
      end
    end

    #
    # generate_report
    #
    # generate a report for one student
    #
    def self.generate_report(student, gradebook, out, report_dir)
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

        if !category.has_key?(:empx) || category[:empx]
          #puts "Generating breakdown for #{category.inspect}"
          generate_mark_breakdown(student, category, out, report_dir)
        else
          #puts "*NOT* Generating breakdown for #{category[:key]}"
        end

        current_grade = gradebook.calc_grade(student, category: category[:key])
        out.puts
        out.printf "Projected grade:  #{current_grade}\n" if current_grade
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
    def self.generate_mark_breakdown(student, category, out, report_dir)
      assigned = category[:assignment_names].length
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

      imagePath = "#{report_dir}/#{student.info[:github]}/#{category[:title].delete(" ")}.png"
      system("node lib/generate_graph.js #{imagePath} #{category[:title].delete(" ")} #{mark_count[:m] + mark_count[:e]} #{assigned}")

      out.puts
      out.puts "![#{category[:title]}](#{category[:title].delete(" ")}.png)"
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
  end # class ReportGenerator
end # module Poprawa
