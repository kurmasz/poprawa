#################################################################################################
#
# System/end-to-end tests for the GitHub progress report command line.
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2022
#
##################################################################################################
require "spec_helper"
require "rubyXL"

describe "gh_progress_report command line" do
  xit "displays a helpful error message if the config file contains a syntax error" do
    # The syntax error will be that we are passing a .csv file instead of an .rb file
    result = run_workbook_builder(test_data("test_csv_student_roster.csv"))

    expect(result[:err]).to include("Syntax error in config file:")

    expect(result[:err].length).to be >= 2
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  xit "displays a helpful message and stack trace if config file raises exception" do
    result = run_workbook_builder(test_data("bad_configs/config_with_exception.rb"))

    expect(result[:err]).to include("Exception thrown while evaluating config file:")
    expect(result[:err]).to include('undefined method `another_method\' for nil:NilClass')
    expect(result[:err]).to include_line_matching(/bad_configs\/config_with_exception.rb:2:in \`a_method\'$/)

    expect(result[:err].length).to be >= 3
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  xit "displays a helpful message if the config file doesn't return a Ruby Hash" do
    result = run_workbook_builder(test_data("bad_configs/config_non_hash_return.rb"))

    expect(result[:err]).to include("Config file must return a Ruby Hash.")

    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  xit "displays a helpful message if no gradebook_file is specified" do
    result = run_workbook_builder(test_data("bad_configs/config_no_gradebook_file.rb"), input: "yes")

    expect(result[:err]).to include("Config must include a gradebook_file item.")

    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if output is not specified and no --output flag used"

  xit "displays a helpful message and exists when categories not specified" do
    result = run_workbook_builder(test_data("bad_configs/config_no_categories.rb"))

    expect(result[:err]).to include("Config must include a :categories item.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  xit "displays a helpful message and exists when categories is present but empty" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), options: "--merge=\"{categories: []}\"")

    expect(result[:err]).to include("Config must include a :categories item that is not empty.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exists when categories is not an array"

  xit "displays a helpful message and exits when category key not specified" do
    merge_hash = {
      categories: [
        {
          key: :learningObjectives,
          title: "Learning Objectives",
          short_title: "LO",
        },
        {
          title: "Homework",
          short_title: "HI",
        },
        {
          key: :projects,
          title: "Project",
          short_title: "P",
        },
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge_hash: merge_hash)

    expect(result[:err]).to include("Config must include a :key for each category.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits when category key not specified"

  it "displays a helpful message and exits when category title not specified"

  it "displays a helpful message and exits when category short_title not specified"

  it "uses first worksheet at info sheet if not specified"

  it "uses default info_sheet_config when not specified" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"))

    workbook = RubyXL::Parser.parse("spec/output/builder/testConfig.xlsx")

    first_row = workbook["info"][0]

    expect(first_row.cells[0].value).to eq "Last Name"
    expect(first_row.cells[1].value).to eq "First Name"

    expect(result[:err].length).to eq(0)
    expect(result[:out].length).to be > 0

    expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
  end

  # I don't remember if there is a default type to verify 
  # or if type must be specified.
  it "validates type if necessary"
end
