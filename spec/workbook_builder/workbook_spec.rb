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

describe "resulting workbook" do

  before(:each) do
    clean_test_output
  end

  # TODO: Change this to actually look at the workbook
  it "generates file specified by config" do
    result = run_workbook_builder(test_data('workbook_builder_config.rb'))

    expect(result[:out]).to include_line_matching(/^Workbook written to .*testWorkbook.xlsx/)

    expect(result[:err].length).to be 0
    expect(result[:out].length).to be 1

    output_file = test_output('testWorkbook.xlsx')
    expect(File.exist?(output_file)).to be true
  end
end