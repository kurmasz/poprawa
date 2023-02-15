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

  NUM_STUDENTS = 15
  NUM_INFO_COLS = 6
  COLS = "ABCDEFG"


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

  # Put the test output in a directory named "builder"
  # We clean this directory before running the test instead of after
  # so that in the event of a test fail, the resulting .xlsx file is
  # left around so we can examine it.
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
    first_row_headers = info_sheet[0].cells.map { |c| c&.value }
    expect(first_row_headers).to eq(["Last Name", "First Name", "Username", "Section", "GitHub", "Major"])

    # Check the headers in row 2 (as specified in the config)
    second_row_headers = info_sheet[1].cells.map { |c| c&.value }
    expect(second_row_headers).to eq(["lname", "fname", "username", "section", "github", "major"])

    # Check that there are the correct number of rows, and the first column is correct.
    lnames = []
    info_sheet.each do |row|
      lnames[row.index_in_collection] = row[0].value
    end
    expect(lnames).to eq(["Last Name", "lname", "Anderson", "Brown", "Davis", "Evans", "Flores", "Garcia", "Hernandez", "Jackson", "Kim", "Lee", "Martinez", "Nelson", "Ortiz", "Patel", "Quinn"])

    # Pick three rows to check carefully:

    first_student = info_sheet[2].cells.map { |c| c&.value }
    expect(first_student).to eq(["Anderson", "Leila", "andersol", 1])
    
    middle_student = info_sheet[9].cells.map { |c| c&.value }
    expect(middle_student).to eq(["Jackson", "Rohan", "jacksonr", 1])

    last_student = info_sheet[16].cells.map { |c| c&.value}
    expect(last_student).to eq(["Quinn", "Allison", "quinna", 2])
  end

  def verify_category(workbook, category)
    sheet = workbook[category]
    expect(sheet).not_to be_nil

    i = 0
    sheet.each do |row|
      # Make sure there aren't any blank rows.
      expect(row.index_in_collection).to be i

      # Make sure all the data are formulas linking back to the info sheet.
      expect(row.cells.length).to be NUM_INFO_COLS
      row.cells.each_with_index do |cell, index|        
        expect(cell.formula).not_to be_nil, "Cell #{COLS[index]}#{i+1} has a nil formula"
        expect(cell.formula.expression).to eq("info!#{COLS[index]}#{i+1}")
      end
      i += 1
    end # each row
    expect(i).to be (NUM_STUDENTS + 2)
  end


  it "contains categories that link to info" do 
    workbook = run_builder("workbook_builder_config.rb", "builder/testWorkbook.xlsx")

    verify_category(workbook, "learningObjectives")
    verify_category(workbook, "homework")
    verify_category(workbook, "projects")
  end

end
