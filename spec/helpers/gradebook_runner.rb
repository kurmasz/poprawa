require "open3"
require "fileutils"
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
  WORKBOOK_BUILDER_COMMAND = "#{File.dirname(__FILE__)}/../../bin/workbook_builder.rb"
  GHPR_COMMAND = "#{File.dirname(__FILE__)}/../../bin/gh_progress_report.rb"
  TEST_DATA = "#{File.dirname(__FILE__)}/../data"
  TEST_OUTPUT = "#{File.dirname(__FILE__)}/../output"

  def test_data(file)
    "#{TEST_DATA}/#{file}"
  end

  def test_output(file)
    "#{TEST_OUTPUT}/#{file}"
  end

  def gh_output(file=nil)
    "#{TEST_OUTPUT}/poprawa-github-test/#{file}"
  end

  def clean_dir(dirname) 
    if File.exist?(dirname) 
      FileUtils.remove_entry_secure(dirname)
    end
    FileUtils.mkdir(dirname)
  end

  def clean_test_output
    $stderr.puts "Cleaning test output: #{TEST_OUTPUT}"
    $stderr.puts "This isn't ready yet.  I don't think we want to unlink the github helper!"
    exit
    Dir.children(TEST_OUTPUT).reject {|f| f.start_with?('.')}.each do |f|
      $stderr.puts "About to unlink #{f} -- #{f.inspect}"
      File.unlink(test_output(f))
    end
  end

  # (1) Run the program under test as an external process.
  # (2) Split the resulting standard output and standard error into an array of lines.
  # (3) Verify that the standard error and standard error end with a newline
  # (5) Verify that there aren't any extra newlines.
  def run_helper(command_line, allow_trailing_blank_lines, input=nil)
    puts "Running command =>#{command_line}<=" if EnvHelper.debug_mode?
    puts "(with input =>#{input})" if EnvHelper.debug_mode? && !input.nil?
    result = ExternalRunner.run(command_line, input)

    if (EnvHelper.debug_mode?)
      puts "Stdout: "
      puts result[:out]
      puts "\nStderr: "
      puts result[:err]
    end

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

  def run_workbook_builder(*args, input: nil, options: nil)
    command = "#{WORKBOOK_BUILDER_COMMAND} #{args.join(" ")}"
    command += " #{options}" if options
    run_helper(command, false, input)
  end

  def run_ghpr(*args, input: nil)
    command = "#{GHPR_COMMAND} #{args.join(" ")}"
    run_helper(command, false, input)
  end
end
