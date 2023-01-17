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
require "poprawa/student"

module Poprawa
  class GradebookLoader

    # Convert 0-based column indexes into letters.
    # From https://stackoverflow.com/questions/13578555/convert-spreadsheet-column-index-into-character-sequence
    COLUMN_INDEX_HASH = Hash.new { |hash, key| hash[key] = hash[key - 1].next }.merge({ 0 => "A" })

    def self.put_error(str)
      $stderr.puts str
    end

    def self.put_warning(str)
      puts str
    end

    #
    # strip_to_nil
    #
    # Return nil if the string is empty or contains only whitespace
    # otherwise, return the stripped string.
    #
    def self.strip_to_nil(str)
      return nil if str.nil?
      stripped = str.to_s.strip
      stripped.empty? ? nil : stripped
    end

    #
    # cell_location
    #
    # Return a string describing the cell's location
    # as Excel does (e.g., A1, B7, AZE44)
    def self.cell_location(cell)
      "#{COLUMN_INDEX_HASH[cell.column]}#{cell.row}"
    end

    def self.cell_location_by_index(row, column)
      "#{COLUMN_INDEX_HASH[column]}#{row}"
    end

    #
    # load
    #
    # Load an Excel workbook by file name
    #
    def self.load(filename, config, verbose: false)
      workbook = RubyXL::Parser.parse(filename)
      info_sheet = student_info_worksheet(workbook, config[:info_sheet_name])
      num_info_columns = config[:info_sheet_config].count

      student_map = self.load_info(info_sheet)

      config[:categories].each do |category|
        sheet_name = category[:key].to_s
        category[:assignment_names] = self.load_gradesheet(workbook[sheet_name], student_map, num_info_columns)
      end

      yield student_map.values
    end # load method

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
    # load_long_name_header
    #
    # Row 0 (the top row) is the "Display names" (easily understandable, human-readable names)
    #
    def self.load_long_name_header(row, sheet_name)
      # TODO Test me
      if row.nil?
        put_error "ERROR: Worksheet #{sheet_name} is missing the Long Name header row (the row labeled 1 in Excel)."
        exit Poprawa::ExitValues::SPREADSHEET_ERROR
      end

      # Note: Empty / missing cells here are not necessarily a problem.
      # They may just represent an unused column.
      row.cells.map { |cell| strip_to_nil(cell&.value&.to_s) }
    end

    #
    # load_short_name_header
    #
    # Row 1 (the second row) is the "short" names (the symbols used internally to reference the data)
    #
    def self.load_short_name_header(row, sheet_name)
      # TODO Test me
      if row.nil?
        put_error "ERROR: Worksheet #{sheet_name} is missing the Short Name header row (the row labeled 2 in Excel)."
        exit Poprawa::ExitValues::SPREADSHEET_ERROR
      end

      # Note: Empty / missing cells here are not necessarily a problem.
      # They may just represent an unused column.
      row.cells.map do |cell|
        stripped_value = strip_to_nil(cell&.value&.to_s)

        # TODO: Test Me
        put_warning "Warning! Assignment key '#{stripped_value}' contains whitespace." if stripped_value =~ /\s+/
        stripped_value.to_sym
      end
    end # load_short_name_header

    #
    # load_gradesheet
    #
    # This method returns a hash containing assignment names & descriptions
    # in addition to loading student grades.
    #
    def self.load_gradesheet(sheet, students, num_info_columns)
      assignment_names = {}
      first_assignment_column = nil

      # Handle rows 0 and 1 (which contains the "display" names and "short" names respectively)
      long_names = load_long_name_header(sheet[0], sheet.sheet_name)
      short_names = load_short_name_header(sheet[1], sheet.sheet_name)

      # TODO: Look through both long_names and short_names and produce a
      # warning if there is a short name without a long name.

      sheet.each do |row|

        # nil rows are not necessarily a big deal.  If the user enters data in a row, then pulls it back out,
        # the row object may still be recorded as nil in the underlying data structure.
        #
        # TODO There is only an issue if there is not a row for each student.
        next if row.nil?

        # We already handled the first two rows
        next if row.index_in_collection < 2

        # Collect the values in each cell.
        cell_values = row.cells.map { |cell| strip_to_nil(cell&.value)}

        # If every cell in the row is empty / nil, then move on.
        next if cell_values.reject { |item| item.nil?}.length == 0

        # TODO: This code assumes students appear in the same row in each
        # worksheet.  There is probably no need to maintain this strict of a structure.
        # Consider searching for the student based on the data in the info columns (e.g., matching by username)

        # Get Student object for this row.
        # (add 1 row so it matches the row number in the spreadsheet)
        student = students[row.index_in_collection + 1]
        # TODO Test me.
        if student.nil?
          put_error "ERROR: Info worksheet doesn't have a student on row #{row.index_in_collection + 1}."
          exit Poprawa::ExitValues::SPREADSHEET_ERROR
        end

        # skip to next student row if inactive
        next unless student.active?

        # Handle the grade columns 
        # (We use the for .. in syntax using the length of short_names 
        # instead of .each in case there is a missing cell at the end of the row.)
        for index in num_info_columns..short_names.length
          value = cell_values[index]

          has_short_name = !short_names[index].nil?

          # don't process data in assignments that are marked with 'x'
          process_this_column = has_short_name && !short_names[index].start_with?("x")

          # Move on if we aren't processing this column yet
          next if value.nil? && !process_this_column

          # Complain if we are processing this column but there is no value
          if value.nil? && process_this_column
            # TODO Test me
            put_warning "WARNING: #{sheet.sheet_name} #{long_names[index]} (#{short_names[index]}) Grade missing for #{student.full_name} (Cell #{cell_location_by_index(row.index_in_collection ,index)})"
          end

          # Complain if there is a value in a column that does not have a short name
          if !value.nil? && !has_short_name
            put_warning "WARNING: There is grade data in cell #{cell_location(cell)} for #{sheet.sheet_name}, but this column doesn't have a short name."
          end

          # Finally, a valid grade in a valid column!
          if !value.nil? && process_this_column
            info = parse_mark_cell(value)
            if (info[:mark].nil?)
              put_warning "Warning! grade for #{student.full_name} on row #{row.index_in_collection + 1} index #{index}: #{info[:message]}"
            end
            student.set_mark(sheet.sheet_name.to_sym, short_names[index], info[:mark])
            student.set_late_days(sheet.sheet_name.to_sym, short_names[index], info[:late])
          end # if process this grade.
        end # foreach column
      end # foreach row

      # create hash from long and short name arrays
      assignment_short_names = short_names.drop(num_info_columns)
      long_names.drop(num_info_columns).each_with_index do |value, index|
        next if assignment_short_names[index].start_with?("x")
        assignment_names[assignment_short_names[index].to_sym] = value.to_sym
      end
      return assignment_names
    end # load_gradesheet

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
