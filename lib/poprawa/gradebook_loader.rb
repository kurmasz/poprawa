#####################################################################################
#
# GradebookLoader
#
# Loads data from an Excel-based gradebook.
#
# Student info worksheet is assumed to be the first (leftmost) worksheet.
#
# Conventions:
#  * All Worksheets
#    * If first (leftmost) column of a row begins with "xx", then that row is ignored.
#    * Rows after END are ignored.
#  * Student Info
#    * Student info is in the first (leftmost) Worksheet
#    * First row of the Info worksheet contains "display" names (i.e., long, descriptive names)
#    * Second row of info worksheet contains Ruby symbols used to access the info in that column.
#      (In other words, this row contains the symbols used as keys in the Student class's @info Hash)
#      Values in this row should "look like" Ruby symbols (lower-case, no whitespace,
#      alphanumeric characters only, etc.)
#  * Grade Worksheets
#    * First row of a grade worksheet contains "display" names (i.e., long, descriptive names)
#    * Second row of a grade worksheet contains Ruby symbols used to access the info in that column.
#      (For example, the second row contains the symbols that serve as an assignment's unique id.)
#      Values in this row should "look like" Ruby symbols (lower-case, no whitespace,
#      alphanumeric characters only, etc.)
#    * First several columns will be formulas that reference a column in the Info worksheet.
#      (This places the students name, and other  select student information in each grade worksheet
#      so it is easy to enter data into that worksheet.)
#      Formulas are assumed to be these references.  Actual grading data (including headers) should be
#      entered directly in the cell (i.e., not be formulas)
#
#
# (c) 2022 Zachary Kurmas
######################################################################################

require "rubyXL"
require 'poprawa/student'

module Poprawa
  class GradebookLoader
    def self.put_error(str)
      puts str
    end

    def self.put_warning(str)
      puts str
    end

    #
    # load
    #
    # Load an Excel workbook by file name
    #
    def self.load(filename, config, verbose: false)
      workbook = RubyXL::Parser.parse(filename)
      info_sheet = student_info_worksheet(workbook, config[:info_sheet_name])

      student_map = self.load_info(info_sheet)

      config[:categories].each do |category|
        sheet_name = category[:key].to_s
        category[:assignment_names] = self.load_gradesheet(workbook[sheet_name], student_map)
      end

      yield student_map.values
    end

    #
    # student_info_worksheet
    #
    # Get the Student Info worksheet.
    # It is assumed to be the first/leftmost sheet unless a name is provided.
    #
    def self.student_info_worksheet(workbook, info_sheet_name = nil)
      if (info_sheet_name.nil?)
        return workbook[0]
      else
        info_sheet = workbook[info_sheet_name]
        if info_sheet.nil?
          put_error "Error: Unable to load info sheet with name '#{info_sheet_name}'."
          exit
        end
        info_sheet
      end
    end

    #
    # load_info
    #
    # Load the Worksheet with the student info (names, etc.)
    #
    def self.load_info(info_sheet)
      students = {}
      info_map = {}

      info_sheet.each do |row|
        next if row.nil?

        # Skip the first row, which is for display purposes only.
        next if row.index_in_collection == 0

        # Grab info symbols
        if (row.index_in_collection == 1)
          row.cells.each_with_index do |cell, index|
            next if cell.nil?                   # skip completely empty cells
            next if cell.value.strip.empty?     # skip cells containing whitespace only.

            # warn about cells that don't "look like" symbols
            stripped_cell = cell.value.strip
            put_warning "Warning! Student info key '#{stripped_cell}' contains whitespace." if stripped_cell =~ /\s+/
            put_warning "Warning! Student info key '#{stripped_cell}' is not lowercase." unless stripped_cell == stripped_cell.downcase

            info_map[index] = stripped_cell.to_sym
          end
        else
          if row[0].nil? || row[0].value.strip.empty?
            put_warning "Warning! Student info row #{row.index_in_collection + 1} has empty left column."
            next
          end

          # ignore all rows after END
          break if row[0].value.strip == "END"

          active = !row[0].value.strip.start_with?("xx")

          student_info = {}
          info_map.each do |column_num, info_key|
            cell_value = nil
            if (row[column_num].nil?)
              put_warning "Warning! Column for #{info_key} in row #{row.index_in_collection + 1} is nil."
            elsif (stripped_string(row[column_num].value).empty?)
              put_warning "Warning! Column for #{info_key} in row #{row.index_in_collection + 1} is empty."
            else
              cell_value = row[column_num].value.to_s.strip
            end
            student_info[info_key] = cell_value
          end
          # 1 is added to index in collection so that it matches the row number observed in the spreadsheet.
          # (This makes debugging *much* easier.)
          student_index = row.index_in_collection + 1
          students[student_index] = Student.new(student_info, student_index, active: active)
        end
      end # info_sheet.each
      students
    end # load_info

    #
    # load_gradesheet
    #
    # This method returns a hash containing assignment names & descriptions
    # in addition to loading student grades.
    #
    def self.load_gradesheet(sheet, students)
      short_names = []
      long_names = []
      assignment_names = {}
      first_assignment_column = nil

      sheet.each do |row|
        if row.nil? 
          # TODO Need to check if this matters or not.
          # TODO Stop at the end of the names
          $stderr.puts "Warning! current row in #{sheet.sheet_name} is nil."
          next
        end

        row.cells.each_with_index do |cell, index|

          # warn about empty cells and skip
          if cell.nil? || cell.value.nil? || cell.value.to_s.strip.empty?
            put_warning "Warning! row #{row.index_in_collection + 1} column #{index + 1} in #{sheet.sheet_name} is empty."
            p row.cells
            exit
            next
          end

          stripped_cell = cell.value.to_s.strip

          # skip cells that contain student info (checks formulas only in the first row)
          if (!first_assignment_column.nil? && index >= first_assignment_column) || cell.formula.nil?
            first_assignment_column = index if first_assignment_column.nil?

            # Process the row with "long names"
            if row.index_in_collection == 0
              long_names.append(stripped_cell)
            end

            # Process the row with "short names"
            if row.index_in_collection == 1
              put_warning "Warning! Assignment key '#{stripped_cell}' contains whitespace." if stripped_cell =~ /\s+/
              short_names.append(stripped_cell.to_sym)
            end

            # Process the rows containing student grades
            if row.index_in_collection > 1
              # add 1 row so it matches the row number in the spreadsheet
              student = students[row.index_in_collection + 1]

              if student.nil?
                puts "Don't have student for #{row.index_in_collection}"
              end

              # skip to next student row if inactive
              break unless student.active?

              # don't process data in assignments that are marked with 'x'

              if short_names[index - first_assignment_column].nil?
                puts "There is data in column #{index}, but no header."
              end

              if !short_names[index - first_assignment_column].start_with?("x")

                # QQQQ info contains mark and late days
                info = parse_mark_cell(cell.value)
                if (info[:mark].nil?)
                  put_warning "Warning! grade for #{student.full_name} on row #{row.index_in_collection + 1} index #{index}: #{info[:message]}"
                end
                student.set_mark(sheet.sheet_name.to_sym, short_names[index - first_assignment_column], info[:mark])
                student.set_late_days(sheet.sheet_name.to_sym, short_names[index - first_assignment_column], info[:late])
              end
            end
          end
        end
      end
      # create hash from long and short name arrays
      long_names.each_with_index do |value, index|
        next if short_names[index].start_with?("x")
        assignment_names[short_names[index].to_sym] = value.to_sym
      end
      return assignment_names
    end

    #
    # parse_mark_cell
    #
    # Parse a cell containing a mark for an assignment.
    # Assume value is not nil.
    def self.parse_mark_cell(value)
      raise "Programmer Error: The value parameter to parse_mark_cell should not be nil" if value.nil?

      answer = {}

      #
      # Mark format:  mark | late days ; comment
      # Mark can be anything except a | or ;
      # Late days must be a number.
      #
      result = (value.to_s =~ /^\s*([^|;]+)\s*(?:\|\s*(\d+)\s*)?(?:\;\s*(.*))?\s*$/)
      if (result.nil?)
        answer = { mark: nil, message: "=>#{value}<= doesn't parse!" }
      elsif $1.nil?
        raise "Programmer Error: This should not be possible"
      elsif $1.strip.empty?
        answer = { mark: nil, late: ($2&.strip)&.to_i, comment: $3&.strip, message: "Mark is empty in =>#{value}<=" }
      else
        # &.strip only calls strip if not nil
        answer = { mark: $1&.strip, late: ($2&.strip)&.to_i, comment: $3&.strip }
      end
      # puts "Mark =>#{value}<= #{answer.inspect} ==== #{$1} -- #{$2}"
      # QQQQ Notice that answer contains both the grade and late days
      answer
    end

    # TODO Perhaps put method on #Object?
    def self.stripped_string(obj)
      obj.to_s.strip
    end
  end # class GradebookLoader
end # module Poprawa
