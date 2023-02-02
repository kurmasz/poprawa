#################################################################################################
#
# System/end-to-end tests for the workbook build by workbook_builder.
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2022
#
##################################################################################################
require "spec_helper"
require "rubyXL"

describe "resulting workbook" do
  def run_builder(config, workbook_filename)
    result = run_workbook_builder(test_data(config))
    expect(result[:out]).to include_line_matching(/^Workbook written to .*\.xlsx/)
    expect(result[:err].length).to be 0
    expect(result[:out].length).to be 1

    output_file = test_output(workbook_filename)
    expect(File.exist?(output_file)).to be true

    # open and return the resulting workbook
    RubyXL::Parser.parse(output_file)
  end

  let(:output_dir) { test_output("builder") }
  before(:each) do
    clean_dir(output_dir)
  end

  it "contains an info sheet with student data" do
    workbook = run_builder("workbook_builder_config.rb", "builder/testWorkbook.xlsx")

    # There should be a Worksheet named "info" (as specified in the config)
    info_sheet = workbook["info"]
    expect(info_sheet).not_to be_nil

    # Check the headers in row 1 (as specified in the config)
    first_row_headers = info_sheet[0].cells.map {|c| c.value}
    expect(first_row_headers).to eq(["Last Name", "First Name", "Username", "Section", "GitHub", "Major"])

  end
end
