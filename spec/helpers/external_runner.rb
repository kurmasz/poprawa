require 'open3'

#############################################################################################
#
# Runs external processes and returns the standard output, standard error, and return value
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2017
#
##############################################################################################
module ExternalRunner

  # Launch the external process specified by the command_line, then return a hash containing
  # the contents of the process's standard output, standard error, and the return value.
  def self.run(command_line, input=nil)
    Open3.popen3(command_line) do |i, o, e, t|
      i.puts input unless input.nil?
      i.close # this implementation assumes that the external process does not use the standard input
      out_reader = Thread.new { o.read }
      err_reader = Thread.new { e.read }

      out_reader.join
      err_reader.join
      # puts "exit value is =>#{t.class}<="

      # if wait_thread is nil, then we are running a ruby version of 1.8 or older.
      if t.nil?
        abort("This function requires Ruby 1.9 or above.  (popen3 doesn't work as expected in Ruby 1.8 or lower.)")
      end

      { out: out_reader.value, err: err_reader.value, exit: t.value.exitstatus }
    end # popen3 block
  end # run

end # module
