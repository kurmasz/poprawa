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

    it "asks before overwriting the output file (when specified by config file)" do
      output_file = "#{output_dir}/testWorkbook.xlsx"
      File.open(output_file, "w") { |f| f.write("Existing test xlsx") }
      orig_size = File.size(output_file)

      result = run_workbook_builder(test_data("workbook_builder_config.rb"), input: "yes")
      expect(File.exist?(output_file)).to be true

      # Make sure we asked
      expect(result[:out]).to include_line_matching(/^Output file.*Overwrite\?$/)
      expect(result[:out]).to include_line_matching(/^Overwriting\.$/)

      # Make sure the current output file is different from the "dummy"
      expect(File.size(output_file)).to be > orig_size

      # Make sure the newly generated file is an xlsx file (check the "magic number")
      # https://stackoverflow.com/questions/60491746/how-to-check-if-the-browsed-file-is-xlsx-or-csv
      File.open(output_file, "r") do |f|
        magic_number = (1..4).map { f.getbyte }
        expect(magic_number).to eq [0x50, 0x4b, 0x03, 0x04]
      end
    end

    it "exits without writing if the user declines to overwrite" do
      output_file = "#{output_dir}/testWorkbook.xlsx"
      File.open(output_file, "w") { |f| f.write("Existing test xlsx") }
      orig_size = File.size(output_file)

      result = run_workbook_builder(test_data("workbook_builder_config.rb"), input: "no")
      expect(File.exist?(output_file)).to be true

      # Make sure we asked
      expect(result[:out]).to include_line_matching(/^Output file.*Overwrite\?$/)
      expect(result[:out]).to include_line_matching(/^Exiting without overwriting\.$/)

      # Make sure the current output file is different from the "dummy"
      expect(File.size(output_file)).to eq orig_size

      # Make sure current output file hasn't changed.
      expect(File.read(output_file)).to eq('Existing test xlsx')
    end

    it "overwrites without asking with --force"

    it "generates file specified by --output"
    # Add "--output" to the command line with a different name for the output file.
    # Run the builder
    # verify that the correct file is created.

    it "asks before overwriting the output file (when specified by --output)"
    # Same as above, just provide --output on the command line.


    it "exits without writing if the user declines to overwrite (when specified by --output)" 
    
    it "overwrites without asking with --force (when specified by --output)"

    it "Saves original in ~ file when overwriting"

    it "Saves original in ~ file when overwriting (when specified by --output)"

  end # context
end
