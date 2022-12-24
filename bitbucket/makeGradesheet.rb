#! /usr/bin/env ruby

#####################################################################################
#
# makeGradesheet
#
# Builds a grading workbook in Excel based on student data in .csv form
#
# (c) 2022 Zachary Kurmas
######################################################################################

# TODO:
# 
# Add -o flag for output.
# If input file matches the pattern of course and semester, then use that for default output file
# Save existing output file with ~ first
# Suppress the "Section" column for courses with only one section.



require "csv"
require "date"
require "optparse"
require 'rubyXL'
require 'rubyXL/convenience_methods'

#################################################################
#
# add_headers
#
#################################################################

def add_headers(sheet, headers)
    headers.each_with_index do |item, index|
        sheet.add_cell(0, index, item)
    end
end


#################################################################
#
# add_gradesheet    
#
#################################################################

def add_gradesheet(workbook, info_sheet, name)
    sheet = workbook.add_worksheet(name)
    add_headers(sheet, ['Last Name', 'First Name', 'Section', 'GitHub'])
    
    info_sheet.each_with_index do |row, index|
        sheet.add_cell(index, 0, '', "info!A#{index + 1}") # last name
        sheet.add_cell(index, 1, '', "info!B#{index + 1}") # first name
        sheet.add_cell(index, 2, '', "info!D#{index + 1}") # section
        sheet.add_cell(index, 3, '', "info!E#{index + 1}") # GitHub
    end
end


#################################################################
#
# main
#
#################################################################

options = {}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: makeGradesheet.rb csv_file [options]"

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end

parser.parse!

if ARGV.length < 1
    puts "Must specify .csv file"
    puts parser.banner
    exit
  end
  input_file = ARGV[0]

if ARGV.length >= 2
    output_file = ARGV[1]
else
  output_file = input_file.gsub(".csv", ".xlsx")
end

students = []
CSV.foreach(input_file, headers: :first_row, encoding: 'bom|utf-8') do |row|

    row[4] =~ /[^.]+\.([^.]+)\.[^.]+/

    student = {
        :last => row[0],
        :first => row[1],
        :username => row[2],
        :section => $1.to_i
    }

    # p student
    students << student
end

# https://www.rubydoc.info/gems/rubyXL/1.1.2
workbook = RubyXL::Workbook.new

########################################
#
# Info sheet
#
########################################

# Workbooks appear to be created with a single worksheet named 'Sheet 1'
if workbook.worksheets.size == 1
    info_sheet = workbook.worksheets.first
    info_sheet.sheet_name = 'info'
else
    info_sheet = workbook.add_worksheet('info')
end

add_headers(info_sheet, ['Last Name', 'First Name', 'Username', 'Section', 'GitHub', 'Major'])

students.each_with_index do |student, index|
    adj_index = index + 1
    info_sheet.add_cell(adj_index, 0, student[:last])
    info_sheet.add_cell(adj_index, 1, student[:first])
    info_sheet.add_cell(adj_index, 2, student[:username]) 
    info_sheet.add_cell(adj_index, 3, student[:section])
    info_sheet.add_cell(adj_index, 4, 'TBD')
end   


########################################
#
# add gradesheets
#
########################################
add_gradesheet(workbook, info_sheet, 'learningObjectives')
add_gradesheet(workbook, info_sheet, 'projects')
add_gradesheet(workbook, info_sheet, 'homework')
add_gradesheet(workbook, info_sheet, 'other')


########################################
#
# All Done
#
########################################

workbook.write('out.xlsx')
