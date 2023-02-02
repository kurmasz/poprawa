#################################################################################################
#
# System/end-to-end tests for the workbook builder command line.
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2022
#
##################################################################################################
require "spec_helper"

describe "workbook_builder command line" do
  it "complains if no parameters passed" do
    result = run_workbook_builder()
    expect(result[:err]).to include("Must specify a config file.")
    expect(result[:err]).to include_line_matching(/^Usage: workbook_builder/)

    expect(result[:err].length).to eq 2
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_PARAMETER
  end

  it "displays helpful message if config file not found" do
    result = run_workbook_builder("no_such_file.rb")
    expect(result[:err]).to include('Config file "no_such_file.rb" not found.')

    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_PARAMETER
  end

  it "displays helpful message if config file cannot be opened" do
    cur_dir = GradebookRunner::TEST_DATA #  File.dirname(__FILE__)
    result = run_workbook_builder(cur_dir)
    expect(result[:err]).to include("Could not open config file \"#{cur_dir}\" because")

    expect(result[:err].length).to eq 2
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_PARAMETER
  end

  context do
    let(:output_dir) { test_output("builder") }

    before(:each) do
      clean_dir(output_dir)
    end

    it "generates file specified by config" do
      result = run_workbook_builder(test_data("workbook_builder_config.rb"))

      expect(result[:out]).to include_line_matching(/^Workbook written to .*testWorkbook.xlsx/)

      expect(result[:err].length).to be 0
      expect(result[:out].length).to be 1

      output_file = "#{output_dir}/testWorkbook.xlsx"
      expect(File.exist?(output_file)).to be true
    end

    it "asks before overwriting the output file (when specified by config file)"
     # create a file with the name of the output file (builder/textWorkbook.xlsx)
     # Then run the builder. (Need to put a "y" on stdin)
     # Verify that it asks if you want to overwrite
     # Verify that the file is created (and is different from the one that was there.)

    it "exits without writing if the user declines to overwrite"
     # create a file with the name of the output file (builder/textWorkbook.xlsx)
     # Then run the builder. (Need to put a "n" on stdin)
     # Verify that it asks if you want to overwrite
     # Verify that the file is created (and is different from the one that was there.)

    it "generates file specified by --output"
    # Add "--output" to the command line with a different name for the output file.
    # Run the builder
    # verify that the correct file is created.

    it "asks before overwriting the output file (when specified by --output)"
    # Same as above, just provide --output on the command line.
  end # context
end
