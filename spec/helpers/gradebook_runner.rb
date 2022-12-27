require "open3"
require_relative "external_runner"

#################################################################################################
#
# Describes and interacts with the various Gradebook programs under test
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2022
#
##################################################################################################
module GradebookRunner
  WORKBOOK_BUILDER_COMMAND = "#{File.dirname(__FILE__)}/../../workbook_builder.rb"
  GHPR_COMMAND = "#{File.dirname(__FILE__)}/../../gh_progress_report.rb"
  TEST_DATA = "#{File.dirname(__FILE__)}/../../test-data"

  def test_data(file)
    "#{TEST_DATA}/#{file}"
  end

  # (1) Run the program under test as an external process.
  # (2) Split the resulting standard output and standard error into an array of lines.
  # (3) Verify that the standard error and standard error end with a newline
  # (5) Verify that there aren't any extra newlines.
  def run_helper(command_line, allow_trailing_blank_lines)
    puts "Running command =>#{command_line}<=" if EnvHelper.debug_mode?
    result = ExternalRunner.run(command_line)

    # The split method normally discards trailing empty items (i.e., the empty strings created by a trailing
    # newline).  The -1 parameter suppresses this behavior, allowing us to verify (1) that the output and error always
    # end with a newline, and (2) that there aren't any extra newlines.
    output = result[:out].split(/\n/, -1)
    error = result[:err].split(/\n/, -1)

    # Verify that the standard output and standard error arrays to either (a) be empty, or (b) end with a single
    # empty string.  This indicates that the output ended with a newline, and that there are no extra blank lines at
    # the end.
    expect(output.empty? || output[-1].empty?).to be(true), "Standard output does not end with a newline."
    output.pop # remove the empty string caused by the trailing newline.
    # At this point, the output array should either be empty or contain a *non-empty* string
    unless allow_trailing_blank_lines
      expect(output.empty? || !output[-1].empty?).to be(true), "Standard output has an extra blank line and the end."
    end

    expect(error.empty? || error[-1].empty?).to be(true), "Standard output does not end with a newline."
    error.pop # remove the empty string caused by the trailing newline.
    # At this point, the error array should either be empty or contain a *non-empty* string
    unless allow_trailing_blank_lines
      expect(error.empty? || !error[-1].empty?).to be(true), "Standard output has an extra blank line and the end."
    end

    { out: output, err: error, exit: result[:exit] }
  end

  def run_workbook_builder(*args)
    command = "#{WORKBOOK_BUILDER_COMMAND} #{args.join(" ")}"
    run_helper(command, false)
  end

  def run_ghpr(*args)
    command = "#{GHPR_COMMAND} #{args.join(" ")}"
    run_helper(command, false)
  end
end
