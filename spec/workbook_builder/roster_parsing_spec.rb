#################################################################################################
#
# System/end-to-end tests for the workbook builder's roster parsing.
# (Note: The purpose of this file is not to verify that the workbook is build correctly,
# it is just to verify that errors and omissions in the .csv files are detected and reported.
# workbook_builder.rb verifies that the workbook is built correctly.)
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2023
#
##################################################################################################
require "spec_helper"
require "rubyXL"
require "tempfile"

describe "workbook parser roster parsing" do
  it "Complains if key appears in roster_config but not info_sheet_config" do
    merge = {
      roster_config: [:lname, :fname, :username, :no_such_key],
    }

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Key no_such_key found in roster_config but not in info_sheet_config.$/
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  # wb_config_file_spec verifies that roster_config is present.

  it "Complains if roster config is nil" do
    merge = {
      roster_config: nil,
    }

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Roster config cannot be nil.$/
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "Complains if the roster_config contains an item that is an empty hash" do
    merge = {
      roster_config: [:lname, {}, :username],
    }

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Invalid roster config. Item may not be empty./
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "Complains if the roster_config contains an item that is a Hash with more than one key-value pair" do
    merge_string = "{ roster_config: [:lname, { fname: ->(v) { v }, extra: :stuff }, :username] }"

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge_string)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Invalid roster config. Item has multiple keys:/
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "Complains if the roster_config contains a Hash whose value is not a lambda" do
    merge = {
      roster_config: [:lname, { fname: "Hi there" }, :username],
    }
    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Invalid roster config. Value for fname must be a lambda./
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  # Names in the roster config are converted to symbols. Thus, if strings are used instead of symbols,
  # everything will work as expected. The test for this behavior is in workbook_spec (because the result
  # should be a valid workbook. The code to verify the workbook is valid is in workbook_spec.

  it "Complains if the roster_config contains an item that can't be converted to a symbol" do
    merge = {
      roster_config: [:lname, :fname, 6, :username],
    }

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Roster config keys must be symbols. \(6 is of type Integer.\)$/
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "Complains if the roster_config contains an hash whose key can't be converted to a symbol" do
    merge_string = "{ roster_config: [:lname, { 22 => ->(v) { v } }, :username] }"

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge_string)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Roster config keys must be symbols. \(22 is of type Integer.\)$/
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "Complains if the roster_config contains an item that is an Array" do
    merge = {
      roster_config: [:lname, :fname, [:oops], :username],
    }

    result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge)
    expect(result[:err].length).to be 1
    expect(result[:err]).to include_line_matching /^Roster config keys must be symbols.*is of type Array.\)$/
    expect(result[:out].length).to be 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  def test_parser(field:, id:, config:, test_section: false)
    #
    # Begin by creating a temp .csv input file by using gsub
    # to replace a "good" section of the file with a "bad" section.
    # Then, run the workbook builder and look for the expected
    # error or warning
    #
    # NOTE: This is bit hard to debug because the Tempfile is
    # automatically deleted. Need to set the tempfile up
    # differently next time.

    file_names = {
      bb_classic: "test_bb_classic_student_roster.csv",
      bb_ultra_with_child_id: "test_bb_ultra_student_roster_child_id.csv",
    }
    fail "Unrecognized config '#{config}'" unless file_names.has_key?(config)

    bad_roster = Tempfile.new("bad_roster")
    begin
      good_roster_data = File.read(test_data(file_names[config]))
      bad_roster_data = yield(good_roster_data)
      bad_roster.write(bad_roster_data)
      # $stderr.puts bad_roster_data
      bad_roster.close

      # calling inspect causes the : to appear in front of the symbol
      merge_string = "{ roster_file: \"#{bad_roster.path}\", roster_config: GVConfig::RosterConfig[#{config.inspect}]}"

      # opt = "--merge #{test_data('wb_merge_bb_classic.rb')}"
      result = run_workbook_builder(test_data("workbook_builder_config.rb"), merge: merge_string)
      expect(result[:out]).to include_line_matching(/^Workbook written to .*\.xlsx/)
      if test_section
        expect(result[:out]).to include_line_matching(/^WARNING: #{field} in row.*#{id}.*does not have the expected format.$/)
      else
        expect(result[:out]).to include_line_matching(/^WARNING: Field #{field} in row.*#{id}.*is empty.$/)
      end
      expect(result[:err].length).to be 0
      expect(result[:out].length).to be 2

      workbook_filename = "builder/testWorkbook.xlsx"
      output_file = test_output(workbook_filename)
      expect(File.exist?(output_file)).to be true
    ensure
      bad_roster.close
      bad_roster.unlink
    end
  end

  # Put the test output in a directory named "builder"
  # We clean this directory before running the test instead of after
  # so that in the event of a test fail, the resulting .xlsx file is
  # left around so we can examine it.
  let(:output_dir) { test_output("builder") }
  before(:each) do
    clean_dir(output_dir)
  end

  describe "(BB classic)" do
    it "Complains if a last name is missing" do
      test_parser(field: "lname", id: "garciam", config: :bb_classic) { |s| s.gsub(/^Garcia,/, ",") }
    end

    it "Complains if a last name contains only whitespace" do
      test_parser(field: "lname", id: "garciam", config: :bb_classic) { |s| s.gsub(/^Garcia,/, "  ,") }
    end

    it "Complains if a first name is missing" do
      test_parser(field: "fname", id: "martinep", config: :bb_classic) { |s| s.gsub(/,Pamela,/, ",,") }
    end

    it "Complains if a first name contains only whitespace" do
      test_parser(field: "fname", id: "martinep", config: :bb_classic) { |s| s.gsub(/,Pamela,/, ", ,") }
    end

    it "Complains if a username is missing" do
      test_parser(field: "username", id: "Margie", config: :bb_classic) { |s| s.gsub(/,nelsonm,/, ",,") }
    end

    it "Complains if a Child Course ID is blank" do
      test_parser(field: "Child Course ID", id: "garciam", config: :bb_classic) do |s|
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,")
      end
    end

    it "Complains if a Child Course ID is not parsable" do
      test_parser(field: "Child Course ID", id: "garciam", config: :bb_classic, test_section: true) do |s|
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,not_parsable")
      end
    end

    it "Recognizes empty middle section as unparsable" do
      test_parser(field: "Child Course ID", id: "garciam", config: :bb_classic, test_section: true) do |s|
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,GVCIS343..202320")
      end
    end

    it "Recognizes non-numeric middle section as unparsable" do
      test_parser(field: "Child Course ID", id: "garciam", config: :bb_classic, test_section: true) do |s|
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,GVCIS343.nope.202320")
      end
    end

    it "Recognizes mixed middle section as unparsable" do
      test_parser(field: "Child Course ID", id: "garciam", config: :bb_classic, test_section: true) do |s|
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,GVCIS343.3x.202320")
      end
    end
  end # BB classic

  describe "(BB ultra)" do
    it "Complains if a last name is missing" do
      test_parser(field: "lname", id: "garciam", config: :bb_ultra_with_child_id) { |s| s.gsub(/^"Garcia",/, ",") }
    end

    it "Complains if a last name contains only whitespace" do
      test_parser(field: "lname", id: "garciam", config: :bb_ultra_with_child_id) { |s| s.gsub(/^"Garcia",/, '"",') }
    end

    it "Complains if a Child Course ID is not parsable" do
      test_parser(field: "Child Course ID", id: "kimj", config:  :bb_ultra_with_child_id, test_section: true) do |s|
        s.gsub(/"GVCIS343.05.202320"/, '"not_parsable"')
      end
    end
  end
end # describe workbook parser
