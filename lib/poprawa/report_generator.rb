#####################################################################################
#
# Report Generator
#
#
# (c) 2022 Zachary Kurmas
#####################################################################################

require 'json'

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
        out.puts "## #{category[:title]}"
        out.puts "|#{category[:title]}|Grade|Late Days|"
        out.puts "|------|-------|-------|"

        category[:assignment_names].each do |key, value|
          marks = format_marks(student.get_mark(category[:key], key))
          late_days = student.get_late_days(category[:key], key)

          out.printf "|%s (%s)|%s|%s|\n", value, key, marks, late_days
        end # each item

        if category.has_key?(:empn) || category[:type] == :empn
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
      lo = {
        "mastered": { "A": 10, "B": 9, "C": 9, "D": 8 },
        "total": 11
      }
      h = {
        "mastered": { "A": 10, "B": 10, "C": 9, "D": 9 },
        "total": 11
      }
      
      grades = lo if category[:short_name] == "LO"
      grades = h if category[:short_name] == "H"

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

      js_path = "#{File.dirname(__FILE__)}/../generate_graph.js"
      imagePath = "#{report_dir}/#{category[:short_name]}.png"
      command = "node #{js_path} #{imagePath} #{mark_count[:m] + mark_count[:e]} #{assigned} '#{grades.to_json}'"
      # $stderr.puts command
      system(command)
      out.puts
      out.puts "![#{category[:title]}](#{category[:short_name]}.png)"
    end

    def self.generate_legend(out)
      out.puts
      out.puts "## Legend "
      out.puts "* `e`: Exceeds expectations"
      out.puts "* `m`: Meets expectations"
      out.puts "* `p`: Progressing"
      out.puts "* `n`: Not Yet"
      out.puts "* `x`: Missing"
      out.puts "* `.`: Waiting for submission"
      out.puts "* `d`: Demonstrated but not yet graded"
      out.puts "* `r`: Received but not yet graded"
      out.puts "* `?`: Received; Grading in progress"
      out.puts "* `!`: Error in grade sheet"
    end
  end # class ReportGenerator
end # module Poprawa
