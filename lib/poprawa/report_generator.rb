#####################################################################################
#
# Report Generator
#
#
# (c) 2022 Zachary Kurmas
#####################################################################################

require "json"
require "tempfile"

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
    def self.generate_reports(gradebook, students = gradebook.students, create_dir: false, after: nil)
      students.select { |s| s.active? }.each do |student|
        $stderr.puts student.lname
        locations = setup_student_dir(student, gradebook, create_dir: create_dir)
        unless locations.nil?
          generate_report(student, gradebook, locations[:report_file], locations[:report_dir])
          after.(student) unless after.nil?
        end
      end
    end

    #
    # setup_student_dir
    #
    # loads a student directory and creates an output file
    #
    def self.setup_student_dir(student, g, create_dir: false)
      student_github = student.info[:github]&.strip
      if student_github.nil? || student_github.empty?
        puts "GitHub account not specified for #{student.full_name}."
        return nil
      end

      base_dir = g.config[:output_dir]
      student_dir = "#{base_dir}/#{student_github}"
      filename = "#{student_dir}/README.md"

      if (create_dir && !File.exist?(student_dir))
        puts "Creating directory for #{student.full_name}"
        Dir.mkdir(student_dir)
      end

      # warn about nonexistent directory
      if !File.exist?(student_dir)
        puts "Report directory doesn't exist for #{student.full_name} --- #{student_dir}."
        return nil
      end

      begin
        { report_file: File.open(filename, "w+"), report_dir: student_dir }
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
        late_header = ""
        late_separator = ""

        if category.has_key?(:track_late) && category[:track_late]
          late_header = "Late Days|"
          late_separator = "-------|"
        end

        out.puts "## #{category[:title]}"
        out.puts "|#{category[:title]}|Progress|#{late_header}"
        out.puts "|------|-------|#{late_separator}"

        category[:assignment_names].each do |key, value|
          marks = format_marks(student.get_mark(category[:key], key), category[:type])
          late_days = student.get_late_days(category[:key], key)

          out.printf "|%s (%s)|%s|", value, key, marks
          if category.has_key?(:track_late) && category[:track_late]
            out.printf "%s|", late_days
          end
          out.puts
        end # each item

        generate_mark_breakdown(category[:type], student, category, out, report_dir)

        current_grade = gradebook.calc_grade(student, category: category[:key])
        out.puts
        out.printf "Projected grade:  #{current_grade}\n" if current_grade
      end # each category

      generate_attendance(student, out)
      generate_legend(out)
      out.puts Time.now
      out.close
      # $stderr.puts "End generate report"
    end

    #
    # format_marks
    #
    # returns a formatted string of marks with the highest grade bolded
    #
    def self.format_marks_empn(marks)
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

    def self.format_marks_empn2(marks_in)
      return if marks_in.nil?

      mark_values = { "e" => 3, "m" => 2, "p" => 1 }
      highest = 0
      highest_index = -1

      marks = marks_in.split("")
      at_or_above = ->(base) { marks.select { |m| mark_values.has_key?(m) && mark_values[m] >= mark_values[base] }.count }

      final = "**N**"
      final = "**-**" if marks.count < 2
      final = "**P**" if at_or_above.("p") >= 2
      final = "**M**" if at_or_above.("m") >= 2
      final = "**E**" if at_or_above.("e") >= 2

      return "#{final} (#{marks_in})"
    end

    def self.format_marks_sr2(marks_in)
      marks = marks_in.split("")
      num_s = marks.select { |m| m.downcase == "s" }.count
      final = "**N**"
      final = "**C**" if num_s >= 2
      return "#{final} (#{marks_in})"
    end

    # TODO: Test Me
    def self.format_marks(marks, type)
      method_name = "format_marks_#{type.to_s}"
      if (self.respond_to?(method_name))
        return self.send(method_name, marks)
      elsif type == :letter || type == :other
        return marks
      else
        puts "WARNING: No formatter for type #{type}"
        return marks
      end
    end

    def self.generate_mark_breakdown_sr2(student, category, out, report_dir)
      out.puts
      out.puts
      message = <<~LINE
        To complete a learning objective, you must successfully answer the quiz question for that 
        objective on _two_ separate weeks. When you have done this, you will see a bold-faced "**C**"
        in the Progress column. If you have not yet completed a learning objective, you will see 
        a bold-faced "**N**"

        The letters in parentheses indicate your score on the quizzes offered for that learning objective.
      LINE
      out.puts message
    end

    #
    # generate_mark_breakdown_empn
    #
    def self.generate_mark_breakdown_empn(student, category, out, report_dir)
      assigned = category[:assignment_names].length
      mark_count = { e: 0, m: 0, p: 0, x: 0 }

      category[:assignment_names].each do |key, value|
        marks = student.get_mark(category[:key], key)
        next if marks.nil?

        mark_count[highest_mark(marks)] += 1
      end

      out.puts
      out.puts "|E|M|P|N|"
      out.puts "|------|-------|-------|-------|"
      out.puts "|#{mark_count[:e]}|#{mark_count[:m]}|#{mark_count[:p]}|#{mark_count[:x]}|"
      out.puts
      out.puts "#{mark_count[:e] + mark_count[:m]} at 'm' or better."

      if !category[:progress_thresholds].nil?
        temp_file = Tempfile.new("grades", Dir.pwd)

        # Determine the student's next grade
        next_grade = nil
        category[:progress_thresholds][:meets_expectations].each do |key, value|
          if mark_count[:m] + mark_count[:e] > value
            break
          end
          next_grade = key.to_sym
        end

        # determine how many Ps should be counted towards student's next grade
        counted_p = category[:progress_thresholds][:progressing][next_grade] - category[:progress_thresholds][:meets_expectations][next_grade]
        if counted_p > mark_count[:p]
          counted_p = mark_count[:p]
        end

        # Determine number of attempted but not awarded e, m, or p
        attempted = assigned - (mark_count[:m] + mark_count[:e] + counted_p)

        # puts "attempted: #{attempted}, assigned: #{assigned}, e: #{mark_count[:e]}, m: #{mark_count[:m]}, counted_p: #{counted_p}"

        info = {
          "thresholds": category[:progress_thresholds][:meets_expectations],
          "categories": {
            "M or Better": {
              "earned": mark_count[:m] + mark_count[:e],
              "color": "#a5b899"
            },
            "\"Counted\" P": {
              "earned": counted_p,
              "color": "#d3c0a3"
            },
            "Attempted": {
              "earned": attempted,
              "color": "#d3717d"
            }
          },
          "colors": {
            "font_color": "#cccccc",
            "grid_color": "#cccccc",
            "tick_color": "#cccccc"
          },
          "output_file": "#{report_dir}/#{category[:short_title]}.png"
        }

        temp_file.write(info.to_json)
        temp_file.close

        js_path = "#{File.dirname(__FILE__)}/../generate_graph.js"
        command = "node #{js_path} #{temp_file.path}"
        system(command)
        out.puts
        out.puts "![#{category[:title]}](#{category[:short_title]}.png)"
      end
    end

    # TODO: Test me
    def self.generate_mark_breakdown(type, student, category, out, report_dir)
      return if type.nil?

      generator_name = "generate_mark_breakdown_#{type.to_s}"
      if self.respond_to?(generator_name)
        self.send(generator_name, student, category, out, report_dir)
      elsif type == :other || type == :letter
        return
      else
        puts "WARNING: No generator defined for type #{type}"
        return
      end
    end

    #
    # generate_attendance
    #
    def self.generate_attendance(student, out)
      days_absent = 0
      student.get_attendance.values.each { |status| days_absent += 1 if %w(x s a).include?(status) }

      out.puts
      out.puts "## Attendance "
      out.puts "Days Absent: #{days_absent}"
    end

    #
    # generate_legend
    #
    def self.generate_legend(out)
      out.puts
      out.puts "## Legend "
      out.puts "* `s`: Success (on quiz)"
      out.puts "* `r`: Retry (quiz)"
      out.puts "* `e`: Exceeds expectations (project)"
      out.puts "* `m`: Meets expectations (project)"
      out.puts "* `p`: Progressing (project)"
      out.puts "* `n`: Not Yet (project)"
      out.puts "* `x`: Missing / Not attempted"
      out.puts "* `.`: Waiting for submission"
      out.puts "* `d`: Demonstrated but not yet graded"
      # out.puts "* `r`: Received but not yet graded"
      out.puts "* `?`: Received; Grading in progress"
      out.puts "* `!`: Error in grade sheet"
    end

    #
    # generate_report
    #
    # generate a report for the entire class (per learning objective)
    #
    def self.generate_class_report(gradebook, out)       
      students = gradebook.students.select {|s| s.active? }

      sorts = {
          learningObjectives: lambda { |a, b| b.scan('s').count - a.scan('s').count }
      }


      gradebook.categories.each do |category|
        out.puts "## #{category[:title]}"
    
        next unless sorts.has_key?(category[:key]) 

        $stderr.puts("#{category[:assignment_names].inspect}")

        category[:assignment_names].each do |key, value|
          out.puts "\n### #{value}"
        
          students.sort! do |a, b|
            val1 = a.get_mark(category[:key], key)
            val2 = b.get_mark(category[:key], key)
            sorts[category[:key]].call(val1, val2)
          end
        
          out.puts "|    | Name               | Marks     |"
          out.puts "|----|--------------------|-----------|"          

          students.each_with_index do |student, index| 
            out.puts "|#{index + 1} | #{student.lname}, #{student.fname} | #{student.get_mark(category[:key], key)}|"
          end


        end

    end
  end



  end # class ReportGenerator
end # module Poprawa
