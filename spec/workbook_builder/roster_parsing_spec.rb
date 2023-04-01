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
  def test_parser(field:, id:, config:, test_section: false)

      #
      # Start by creating a temp .csv input file by using gsub 
      # to replace a "good" section of the file with a "bad" section.
      # Then, run the workbook builder and look for the expected 
      # error or warning
      #
      # NOTE: This is bit hard to debug because the Tempfile is 
      # automatically deleted. Need to set the tempfile up 
      # differently next time.

      bad_roster = Tempfile.new("bad_roster")
      begin
        good_roster_data = File.read(test_data("test_bb_classic_student_roster.csv"))
        bad_roster_data = yield(good_roster_data)
        bad_roster.write(bad_roster_data)
        # $stderr.puts bad_roster_data
        bad_roster.close

        merge_hash = { 
          roster_file: bad_roster.path,
          roster_config: config 
        }
        
        result = run_workbook_builder(test_data("workbook_builder_config.rb"), '--merge', test_data(merge_hash))
        expect(result[:out]).to include_line_matching(/^Workbook written to .*\.xlsx/)
        if test_section
          expect(result[:out]).to include_line_matching(/^WARNING: #{field} in row.*#{id}.*does not have the expected format.$/)
        else
          expect(result[:out]).to include_line_matching(/^WARNING: Field #{field} in row.*#{id}.*is empty.$/)
        end
        expect(result[:err].length).to be 0
        expect(result[:out].length).to be 2
    
        workbook_filename = 'builder/testWorkbook.xlsx'
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

  describe "(arbitrary csv)" do
  end

  describe "(BB classic)" do
    it "Complains if a last name is missing" do
      test_parser(field: 'lname', id: 'garciam', config: :bb_classic) {|s| s.gsub(/^Garcia,/, ",")}
    end

    it "Complains if a last name contains only whitespace" do
      test_parser(field: 'lname', id: 'garciam', config: :bb_classic) {|s| s.gsub(/^Garcia,/, "  ,")}
    end

    it "Complains if a first name is missing" do
      test_parser(field: 'fname', id: 'martinep', config: :bb_classic) {|s| s.gsub(/,Pamela,/, ",,")}
    end

    it "Complains if a first name contains only whitespace" do 
      test_parser(field: 'fname', id: 'martinep', config: :bb_classic) {|s| s.gsub(/,Pamela,/, ", ,")}
    end

    it "Complains if a username is missing" do
      test_parser(field: 'username', id: 'Margie', config: :bb_classic) {|s| s.gsub(/,nelsonm,/, ",,")}
    end

    it "Complains if a Child Course ID is blank" do
      test_parser(field: 'Child Course ID', id: 'garciam', config: :bb_classic) do |s| 
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,")
      end
    end

    it "Complains if a Child Course ID is not parsable" do
      test_parser(field: 'Child Course ID', id: 'garciam', config: :bb_classic, test_section: true) do |s| 
        s.gsub(/garciam,,GVCIS343.01.202320/, "garciam,,not_parsable")
      end
    end

  end # BB classic
end # describe workbook parser
