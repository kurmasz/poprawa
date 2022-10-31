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
#    * If first (leftmost) column begins with "xx" that row is ignored.
#    * Rows after END are ignored.
#  * Student Info
#    * Student info is in the first (leftmost) Worksheet
#    * First row of info worksheet contains display names
#    * Second row of info worksheet contains Ruby symbols used to access that info
#      Values in this row should "look like" Ruby symbols (lower-case, no whitespace, 
#      alphanumeric characters only, etc.) 
#  * Grade Worksheets
#    * First row is header containing "long" assignment names
#    * Second row contains "short" assignment names
#    * First several columns will be copies of user data (so it is easy to enter data into workbook)
#    * Second row should be left blank for these student info columns

# (c) 2022 Zachary Kurmas
######################################################################################

require "rubyXL"
require_relative 'student'

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
      category[:item_keys] = self.load_gradesheet(workbook[sheet_name], info_sheet, student_map)
    end

    yield student_map.values
  end

  #
  # student_info_worksheet
  #
  # Get the Student Info worksheet. 
  # It is assumed to be the first/leftmost sheet unless a name is provided.
  #
  def self.student_info_worksheet(workbook, info_sheet_name=nil)
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

        active = !row[0].value.strip.start_with?('xx')

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
  # Load a Worksheet containing student marks
  #   * The first several columns are references to the student info worksheet.
  #     (This is how the user knows whose marks go on which row.)
  #     * It is important that the user data is by reference.  This code
  #       assumes cells with formulas referencing the info sheet are user data
  #       and the remaining cells in a row are grade/mark data.  
  #   * The first row is simply a decorative header row.
  #   * The second row contains the user info symbols followed my the "short name" of 
  #     assignments stored on the sheet.
  #     * These "short names" should look like Ruby symbols. 
  #
  def self.load_gradesheet(sheet, info_sheet, students)

    puts "Loading gradesheet #{sheet.sheet_name}"

    info_map= {}  
    assignment_keys = {}
    first_assignment_column = nil

    sheet.each do |row|

      # ignore the header row
      next if row.index_in_collection == 0

      row_index = row.index_in_collection;

      # Process the row with "short names" for assignments
      if (row.index_in_collection == 1)
        row.cells.each_with_index do |cell, index|

          # Warn about empty cells
          if cell.nil? || cell.value.nil? || cell.value.to_s.strip.empty?
            put_warning "Warning: The cell in column #{index} of the #{sheet.sheet_name} key row is nil or empty"
            next
          end
          
          # Check if cell is a formula pointing to the information sheet
          stripped_cell = cell.value.to_s.strip
          if !cell.formula.nil? && cell.formula.expression =~ /^#{info_sheet.sheet_name}\!\w+2$/
            # TODO Make sure stripped_cell matches key from Student info sheet
            info_map[index] = stripped_cell.to_sym
            # puts "Setting #{index} to #{stripped_cell}"
          else
            first_assignment_column = index  if first_assignment_column.nil?              
            put_warning "Warning! Assignment key '#{stripped_cell}' contains whitespace." if stripped_cell =~ /\s+/
            assignment_keys[index] = stripped_cell.to_sym unless stripped_cell.start_with?('x')
          end
          #p assignment_keys
        end # end each cell for second row
      else 
        # We add 1 row index so it matches the row number in the spreadsheet 
        student = students[row_index+1]
        # puts "#{row_index} #{student.inspect}"
        raise "Programmer Error! Row #{row_index + 1} of #{sheet.sheet_name} Worksheet contains unexpected student." unless row_index = student.index
        next unless student.active?

        row.cells.each_with_index do |cell, index|
          if (index < first_assignment_column) 
            # puts "Key is #{info_map[index].inspect} ---- #{info_map.inspect}"
            # puts "Student info => #{student.info} -- #{student.info[info_map[index]]}"
            put_warning "Warning! Unexpected student info on row #{row_index + 1} column #{index}.  Expected #{student.info[info_map[index]]}.  Got #{cell.value}" unless student.info[info_map[index]] == stripped_string(cell.value)
          elsif assignment_keys.keys.include?(index)  # don't process data in assignments that are marked with 'x'
            if (cell.nil? || cell.value.nil? || cell.value.to_s.strip.empty?)
              put_warning "Warning! #{assignment_keys[index]} grade for #{student.full_name} on row #{row_index + 1} is empty."
            else
              info = parse_mark_cell(cell.value)
              if (info[:mark].nil?) 
                put_warning "Warning! #{assignment_keys[index]} grade for #{student.full_name} on row #{row_index + 1}: #{info[:message]}"
              end
              student.set_mark(sheet.sheet_name.to_sym, assignment_keys[index], info[:mark])
            end # if cell is empty
          end # if user info column
        end # each cell for remaining rows
        assignment_keys.keys.each do |key| 
          if key >= row.cells.count
            put_warning "Warning! #{assignment_keys[key]} grade for #{student.full_name} on row #{row_index + 1} is empty."
          end
        end # each key
      end # if row.index_in_collection == 
    end # each row
    assignment_keys.sort.map {|item| item.last}
  end # end load_gradesheet


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
    result = (value =~ /^\s*([^|;]+)\s*(?:\|\s*(\d+)\s*)?(?:\;\s*(.*))?\s*$/)
    if (result.nil?)
      answer = {mark: nil, message: "=>#{value}<= doesn't parse!"}
    elsif $1.nil?
      raise "Programmer Error: This should not be possible"
    elsif $1.strip.empty?
      answer = {mark: nil, late: ($2&.strip)&.to_i, comment: $3&.strip, message: "Mark is empty in =>#{value}<="}
    else 
      # &.strip only calls strip if not nil
      answer = {mark: $1&.strip, late: ($2&.strip)&.to_i, comment: $3&.strip}
    end
    #puts "Mark =>#{value}<= #{answer.inspect}"
    answer
  end


  # TODO Perhaps put method on #Object?
  def self.stripped_string(obj)
    obj.to_s.strip
  end
end # class GradebookLoader

