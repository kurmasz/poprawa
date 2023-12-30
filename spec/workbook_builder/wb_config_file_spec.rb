#################################################################################################
#
# System/end-to-end tests for the workbook builder configuration file.
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2022
#
##################################################################################################
require "spec_helper"
require "rubyXL"

describe "workbook_builder configuration file" do
  it "displays a helpful error message if the config file contains a syntax error" do
    # The syntax error will be that we are passing a .csv file instead of an .rb file
    result = run_workbook_builder(test_data("test_csv_student_roster.csv"))

    expect(result[:err]).to include("Syntax error in config file:")
    expect(result[:err].length).to be >= 2
    expect(result[:out].length).to eq 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and stack trace if config file raises exception" do
    result = run_workbook_builder(test_data("bad_configs/config_with_exception.rb"))

    expect(result[:err]).to include("Exception thrown while evaluating config file:")
    expect(result[:err]).to include('undefined method `another_method\' for nil:NilClass')
    expect(result[:err]).to include_line_matching(/bad_configs\/config_with_exception.rb:2:in \`a_method\'$/)

    expect(result[:err].length).to be >= 3
    expect(result[:out].length).to eq 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message if the config file doesn't return a Ruby Hash" do
    result = run_workbook_builder(test_data("bad_configs/config_non_hash_return.rb"))

    expect(result[:err]).to include("Config file must return a Ruby Hash.")
    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if no gradebook_file is specified" do
    result = run_workbook_builder(test_data("bad_configs/config_no_gradebook_file.rb"), input: "yes")

    expect(result[:err]).to include("Config must include a gradebook_file item.")
    expect(result[:err].length).to eq 1
    expect(result[:out].length).to eq 0
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if roster_config is not specified" do
    result = run_workbook_builder(test_data("bad_configs/config_no_roster_config.rb"), input: "yes")

    expect(result[:err]).to include("Config must include a :roster_config item specifying the format of the .csv file.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if info_sheet_name is not a string" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: { info_sheet_name: :not_a_string })

    expect(result[:err]).to include(":info_sheet_name must be a string.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if info_sheet_name is empty" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: { info_sheet_name: "" })

    expect(result[:err]).to include(":info_sheet_name cannot be empty.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if info_sheet_config is an empty array" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: { info_sheet_config: [] })

    expect(result[:err]).to include("Config must include an :info_sheet_config item that is not empty.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if info_sheet_config contains an item that is not a Hash" do
    merge_hash = {
      info_sheet_config: [
        { lname: "Last Name" },
        'not a hash',
        { fname: "First Name" },
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)
    expect(result[:err]).to include("All items in :info_sheet_config array must be Hashes.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if info_sheet_config contains a Hash with no items" do
    merge_hash = {
      info_sheet_config: [
        { lname: "Last Name" },
        {},
        { fname: "First Name" },
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)

    expect(result[:err]).to include("No items in :info_sheet_config array can be empty.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if info_sheet_config contains a Hash with more than one item" do
    merge_hash = {
      info_sheet_config: [
        { 
          lname: "Last Name",
          fname: "First Name" 
        }
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)

    expect(result[:err]).to include("No Hash in :info_sheet_config can contain more than one item.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exists when categories not specified" do
    result = run_workbook_builder(test_data("bad_configs/config_no_categories.rb"))

    expect(result[:err]).to include("Config must include a :categories item.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exists when categories is present but empty" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: { categories: [] })

    expect(result[:err]).to include("Config must include a :categories item that is not empty.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exists when categories is not an array" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: { categories: "not an array" })

    expect(result[:err]).to include(":categories item must be an array.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if categories contains an item that is not a Hash" do
    merge_hash = {
      categories: [
        {
          key: :category1,
          title: "Category1",
          short_title: "C1",
        },
        'Category2',
        {
          key: :category3,
          title: "Category3",
          short_title: "C3",
        },
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)

    expect(result[:err]).to include("All items in :categories array must be Hashes.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if categories contains a Hash with no items" do
    merge_hash = {
      categories: [
        {
          key: :category1,
          title: "Category1",
          short_title: "C1",
        },
        {},
        {
          key: :category3,
          title: "Category3",
          short_title: "C3",
        },
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)

    expect(result[:err]).to include("No items in :categories array can be empty.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits when category key not specified" do
    merge_hash = {
      categories: [
        {
          key: :learningObjectives,
          title: "Learning Objectives",
          short_title: "LO",
        },
        {
          title: 'Homework',
          short_title: "HI",
        },
        {
          key: :projects,
          title: "Project",
          short_title: "P",
        },
      ],
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)

    expect(result[:err]).to include("Config must include a :key for each category.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if attendance has no first_sunday" do
    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"),
                                  merge: { attendance: { last_saturday: "2023-4-29", meeting_days: "TR" } })

    expect(result[:err]).to include("Attendance config must include a value for :first_sunday.")

    expect(result[:err].length).to eq 1

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if attendance has no last_saturday" do
    merge_hash = {
      attendance: {
        first_sunday: "2023-1-8",
        meeting_days: "TR"
      }
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)
    expect(result[:err]).to include("Attendance config must include a value for :last_saturday.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  it "displays a helpful message and exits if attendance has no meeting_days" do
    merge_hash = {
      attendance: {
        first_sunday: "2023-1-8",
        last_saturday: "2023-4-29"
      }
    }

    result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)
    expect(result[:err]).to include("Attendance config must include a value for :meeting_days.")
    expect(result[:err].length).to eq 1
    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_CONFIG
  end

  context do
    let(:output_dir) { test_output("builder") }

    before(:each) do
      clean_dir(output_dir)
    end

    it "uses default info_sheet_name when not specified" do
      result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_name.rb"))

      workbook = RubyXL::Parser.parse("spec/output/builder/testConfig.xlsx")

      info_sheet = workbook["info"]
      expect(info_sheet).not_to be_nil

      puts result[:err]

      expect(result[:err].length).to eq(0)
      expect(result[:out].length).to be > 0
      expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
    end

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

    it "doesn't create attendance sheet if attendance item is missing" do
      result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"))

      workbook = RubyXL::Parser.parse("spec/output/builder/testConfig.xlsx")

      attendance_sheet = workbook["attendance"]
      expect(attendance_sheet).to be_nil
    end

    it "creates attendance sheet if attendance item is present" do
      merge_hash = {
        attendance: {
          first_sunday: "2023-1-8",
          last_saturday: "2023-4-29",
          meeting_days: "TR"
        }
      }

      result = run_workbook_builder(test_data("valid_configs/config_no_info_sheet_config.rb"), merge: merge_hash)
      workbook = RubyXL::Parser.parse("spec/output/builder/testConfig.xlsx")
      attendance_sheet = workbook["attendance"]
      expect(attendance_sheet).to_not be_nil
      expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
    end
  end
end
