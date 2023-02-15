output_file = 'spec/output/builder/testWorkbook.xlsx'
File.open(output_file, 'r') do |f| 
  
  v = (1..4).map { f.getbyte}
  p v[0].class
  p v
  #expect(f.read(4)).to be 0x504b0304}
end