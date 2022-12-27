#####################################################################################
#
# Student
#
# Holds personal and grade data for one student.
#
# Data:
#
# @active:     Boolean indicating whether student is still active (or has withdrawn)
#
# @index:      The index of this Student item in the containing array.
#
# @info:       Student data stored in the "info" worksheet.  Most of this data is
#              optional (displayed in the workbook primarily for the convenience of
#              the gradekeeper).  Commonly included items include
#              - fname    (required)
#              - lname    (required)
#              - section
#              - github   (required if posting progress reports to github)
#
# @marks:      A nested Hash (Hash of Hashes) that stores a student's marks for an assignment
#              using both the assignment type (the worksheet name) and assignment "short" name
#              (the symbol in the second row of the corresponding worksheet).  For example,
#              to access the mark for assignment :hw2 in the "homework" worksheet, use
#              @marks[:homework][:hw2].  This Student class does not specify the form of the
#              mark itself; but, the current report_generator assumes the mark is a String.
#
# @late_days:  A nested Hash that stores the number of late days accrued for a given assignment.
#              (See description of @marks above)
#
#
#
# (c) 2022 Zachary Kurmas
######################################################################################

module Poprawa
  class Student

    # Keys required to be present in @info
    REQUIRED_KEYS = [:fname, :lname]

    attr_reader :info, :index

    #
    # Constructor
    #
    def initialize(info_map, index = nil, active: true)
      @active = active
      REQUIRED_KEYS.each do |req_key|
        raise "Required Key #{req_key} missing from Student data" unless info_map.has_key?(req_key)
      end

      @info = info_map
      @index = index
      @marks = {}
      @late_days = {}
    end

    #
    # Get first name
    #
    def fname
      @info[:fname]
    end

    #
    # Get last name
    #
    def lname
      @info[:lname]
    end

    #
    # Get full name
    #
    def full_name
      "#{fname} #{lname}"
    end

    #
    # Is this student inactive?
    #
    def inactive?
      !@active
    end

    #
    # Is this student active?
    #
    def active?
      @active
    end

    # set_mark
    #
    # Set a mark for a specific assignment
    #
    def set_mark(type, assignment, mark)
      @marks[type] = {} unless @marks.has_key?(type)
      @marks[type][assignment] = mark
    end

    #
    # get_mark
    #
    def get_mark(type, assignment)
      @marks[type][assignment]
    end

    def get_marks(type)
      puts "Calling get_marks for #{type}"
      p @marks.keys
      @marks[type].values
    end

    #
    # set_late_days
    #
    def set_late_days(type, assignment, late_days)
      @late_days[type] = {} unless @late_days.has_key?(type)
      @late_days[type][assignment] = late_days.nil? ? 0 : late_days
    end

    #
    # get_late_days
    #
    def get_late_days(type, assignment)
      @late_days[type][assignment]
    end
  end # end class Student
end # module Poprawa
