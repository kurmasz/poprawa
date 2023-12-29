#####################################################################################
#
# GVConfig
#
# These are various methods to simplify the config files in use at GVSU.
# In general, code should probably be moved to an external plug-in system.
# However, we put this code here for now for two reasons:
#   1. To demonstrate what types of things are possible with Poprawa, and
#   2. It will be a while before a more generalized plug-in system makes it
#      to the top of our "to-do" list.
#
#
# (c) 2023 Zachary Kurmas
#####################################################################################

module GVConfig

  ###################################################################################
  #
  # parse_child_course_id
  #
  # We are, unfortunately, stuck with Blackboard. If we merge several sections
  # into a single Blackboard course, the gradebook includes a "Child Course ID"
  # field that looks something like this:  GVCIS343.02.202320
  #
  # This method parses the section number out from the longer child course ID.
  #
  ####################################################################################
  def self.parse_child_course_id(value, row)
    if value.nil?
      puts "WARNING: Field Child Course ID in row \"#{row.to_s.chomp}\" is empty."
      sec_num = -1
    elsif (value =~ /[^.]+\.(\d+)\.[^.]+/).nil?
      puts "WARNING: Child Course ID in row \"#{row.to_s.chomp}\" does not have the expected format."
      sec_num = -1
    else
      sec_num = $1.to_i
    end
    sec_num
  end

  section_hash = { section: method(:parse_child_course_id) }
  RosterConfig = {
    bb_classic: [:lname, :fname, :username, nil, section_hash ],      # old BB classic for a merged course
    bb_ultra_with_child_id: [:lname, :fname, :username, nil, nil, nil, section_hash], # new BB ultra for a merged course
    bb_ultra_no_child_id: [:lname, :fname, :username]                 # new BB ultra for a non-merged course
  }
end # module
