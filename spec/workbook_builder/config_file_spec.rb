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
require "rubyXL"

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

  it "displays a helpful message if no gradebook_file is specified" do
    result = run_workbook_builder(test_data('bad_configs/config_no_gradebook_file.rb'), input: "yes")

    expect(result[:err]).to include('Config must include a gradebook_file item.')

    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if roster_config is not specified" do
    result = run_workbook_builder(test_data('bad_configs/config_no_roster_config.rb'), input: "yes")

    expect(result[:err]).to include('Config must include a :roster_config item specifying the format of the .csv file.')

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  # write one test that complains if it's a string (not an array)
  # ["bb_classic", 14, {type: :bb_classic}, lambda {puts "Hi"}].each do |c| 
  #   it "displays a helpful message and exits if roster_config has type #{c.class}"
  # end

  it "displays a helpful message and exits if roster_config is a symbol, but unrecognized" do
    result = run_workbook_builder(test_data('bad_configs/config_invalid_roster_symbol.rb'), input: "yes")

    puts result[:out]

    expect(result[:err]).to include('Roster config symbol \'invalid_symbol\' not recognized.')

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exists when categories not specified" do
    result = run_workbook_builder(test_data('bad_configs/config_no_categories.rb'), input: "yes")

    expect(result[:err]).to include('Config must include a :categories item.')

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exists when categories is present but empty" do
    result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'), options: "--merge=\"{categories: []}\"")

    expect(result[:err]).to include('Config must include a :categories item that is not empty.')

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits when category title not specified" do
    result = run_workbook_builder(test_data('bad_configs/config_no_category_title.rb'), input: "yes")

    expect(result[:err]).to include('Config must include a :title item for each category.')

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end
  
  it "displays a helpful message and exits if attendance has no first_sunday" do
    result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'), options: "--merge=\"{attendance: {
      last_saturday: \\\"2023-4-29\\\",
      meeting_days: \\\"TR\\\"
    }}\"")

    expect(result[:err]).to include('Config must include a :first_sunday item specifying the date of the first sunday.')

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if attendance has no last_saturday" do
    result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'), options: "--merge=\"{attendance: {
      first_sunday: \\\"2023-1-8\\\",
      meeting_days: \\\"TR\\\"
    }}\"")

    expect(result[:err]).to include('Config must include a :last_saturday item specifying the date of the last saturday.')

    expect(result[:err].length).to eq 1
    
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if attendance has no meeting_days" do
    result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'), options: "--merge=\"{attendance: {
      first_sunday: \\\"2023-1-8\\\",
      last_saturday: \\\"2023-4-29\\\"
    }}\"")

    expect(result[:err]).to include('Config must include a :meeting_days item specifying which days of the week the class meets.')

    expect(result[:err].length).to eq 1
    
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  context do
    let(:output_dir) { test_output("builder")}

    before(:each) do
      clean_dir(output_dir)
    end

    it "uses default info_sheet_name when not specified" do
      result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_name.rb'))
  
      workbook = RubyXL::Parser.parse('spec/output/builder/testConfig.xlsx')
  
      info_sheet = workbook['info']
      expect(info_sheet).not_to be_nil
  
      puts result[:err]
  
      expect(result[:err].length).to eq(0)
      expect(result[:out].length).to be > 0
  
      expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
    end
  
    it "uses default info_sheet_config when not specified" do
      result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'))
    
      workbook = RubyXL::Parser.parse('spec/output/builder/testConfig.xlsx')
  
      first_row = workbook['info'][0]

      expect(first_row.cells[0].value).to eq "Last Name"
      expect(first_row.cells[1].value).to eq "First Name"
    
      expect(result[:err].length).to eq(0)
      expect(result[:out].length).to be > 0
    
      expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
    end

    it "doesn't create attendance sheet if attendance item is missing" do
      result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'))

      workbook = RubyXL::Parser.parse('spec/output/builder/testConfig.xlsx')

      attendance_sheet = workbook['attendance']
      expect(attendance_sheet).to be_nil
    end

    it "creates attendance sheet if attendance item is present" do
      result = run_workbook_builder(test_data('valid_configs/config_no_info_sheet_config.rb'), options: "--merge=\"{attendance: {
        first_sunday: \\\"2023-1-8\\\",
        last_saturday: \\\"2023-4-29\\\",
        meeting_days: \\\"TR\\\"
      }}\"")

      workbook = RubyXL::Parser.parse('spec/output/builder/testConfig.xlsx')

      attendance_sheet = workbook['attendance']

      expect(attendance_sheet).to_not be_nil
      expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
    end
  end
end
