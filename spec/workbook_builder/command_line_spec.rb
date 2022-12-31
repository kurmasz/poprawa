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
    result = run_workbook_builder('no_such_file.rb')
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

  # TODO verify the correct behavior of the output
end
