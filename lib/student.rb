#####################################################################################
#
# Student
#
# Holds personal and grade data for one student.
#
# (c) 2022 Zachary Kurmas
######################################################################################

class Student
  REQUIRED_KEYS = [:fname, :lname]

  attr_reader :info, :index

  #
  # Constructor
  #
  def initialize(info_map, index=nil, active: true)
    @active = active
    REQUIRED_KEYS.each do |req_key|
      raise "Required Key #{req_key} missing from Student data" unless info_map.has_key?(req_key)
    end

    @info = info_map
    @index = index
    @marks = {}
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

  def get_mark_old(item)
    mark_values = { "e" => 2, "m" => 3, "p" => 4, "x" => 5, "." => 6, "?" => 6 }
    mark = @marks[item]
    return mark if mark.nil? || mark.length <= 1
    $stderr.puts "Mark for #{item} is nil" if mark.nil?
    mark.chars.each do |v|
      $stderr.puts "Unknown mark for #{item}:  =>#{v}<=" unless mark_values.has_key?(v)
    end

    mark.chars.sort { |a, b| mark_values[a] <=> mark_values[b] }.first
  end
end
