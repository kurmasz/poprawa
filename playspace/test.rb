require 'rubyXL'
require "rubyXL/convenience_methods"

workbook = RubyXL::Parser.parse('out_no_protection2.xlsx')
sheet = workbook['projects']

p sheet.cols.class
sheet.cols.each { |col| p col}



# puts "Sheet protection"
# p sheet.sheet_protection
# puts
# p workbook.cell_xfs
# puts
workbook.cell_xfs.each_with_index do |i, index|
  puts index
  p i
end

# sheet.each_with_index do |row, r|
#   row.cells.each_with_index do |cell, c|
#     puts "xx #{r} #{c} #{cell&.style_index}"
#   end
# end

# xf = doc.workbook.cell_xfs[c.style_index || 0]
# xf.apply_protection && xf.protection.locked
# xf.apply_protection && xf.protection.hidden


# (0..5).each do |index|
#  p sheet.cols.get_range(index)
#  p sheet.cols.get_range(index).hidden
# end