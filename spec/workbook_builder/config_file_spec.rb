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
    # The syntax error will be that we are passing a .csv file instead of an .rb file
    result = run_workbook_builder(test_data("test_csv_student_roster.csv"))
    expect(result[:err]).to include("Syntax error in config file:")

    expect(result[:err].length).to be >= 2
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and stack trace if config file raises exception" do
    result = run_workbook_builder(test_data('bad_configs/config_with_exception.rb'))

    expect(result[:err]).to include('Exception thrown while evaluating config file:')
    expect(result[:err]).to include('undefined method `another_method\' for nil:NilClass')
    expect(result[:err]).to include_line_matching(/bad_configs\/config_with_exception.rb:2:in \`a_method\'$/)

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

  it "displays a helpful message and uses a default when info_sheet_name not specified"

  it "displays a helpful message and uses a default when info_sheet_config not specified"

  it "displays a helpful message exits if roster_config is not specified"

  ["bb_classic", 14, {type: :bb_classic}, lambda {puts "Hi"}].each do |c| 
    it "displays a helpful message and exits if roster_config has type #{c.class}"
  end

  it "displays a helpful message and exits if roster_config is a symbol, but unrecognized"

  it "displays a helpful message and uses a default when info_sheet_config not specified"


  it "displays a helpful message and exists when categories not specified"

  it "displays a helpful message and exists when categories is present but empty"

  it "displays a helpful message and exits if any category has no key"
  
  it "displays a helpful message and exits if attendance has no first_sunday"

  it "displays a helpful message and exits if attendance has no last_sunday"

end
