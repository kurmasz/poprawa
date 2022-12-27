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
  it "displays a helpful error message if the config file contains a syntax error" do
    result = run_workbook_builder(test_data("demo_grades.xlsx"))
    expect(result[:err]).to include("Syntax error in config file:")

    expect(result[:err].length).to eq 2
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and stack trace if config file raises exception" do
    result = run_workbook_builder(test_data('bad_configs/config_with_exception.rb'))

    expect(result[:err]).to include('Exception thrown while evaluating config file:')
    expect(result[:err]).to include('undefined method `another_method\' for nil:NilClass')
    expect(result[:err]).to include_line_matching(/test-data\/bad_configs\/config_with_exception.rb:2:in \`a_method\'$/)

    expect(result[:err].length).to be >= 3
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message if the config file doesn't return a Ruby Hash" do
    result = run_workbook_builder(test_data('bad_configs/config_non_hash_return.rb'))

    expect(result[:err]).to include('Config file must return a Ruby Hash.')
    
    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end
end
