require 'poprawa/gradebook_loader'

GradebookLoader = Poprawa::GradebookLoader

describe 'parse_mark' do

  def verify_error(answer) 
    expect(answer[:mark]).to be_nil
    expect(answer).to have_key(:message)
    # state of other two keys is unspecified
  end

  # Replace the put_warning method so we don't see 
  # all the warnings the bad input is generating.
  before(:all) do 
    def GradebookLoader.put_warning(str) 
      # do nothing
    end    
  end

  it "returns '!' given an empty cell" do
    answer = GradebookLoader.parse_mark_cell('')
    verify_error(answer)
  end

  it "returns '!' given cell with spaces only" do
    answer = GradebookLoader.parse_mark_cell('                  ')
    verify_error(answer)
  end

  it "returns '!' given cell with whitespace only" do
    answer = GradebookLoader.parse_mark_cell("   \t\t     \t    \t     ")
    verify_error(answer)
  end

  ['m', 'm.', 'Mom', 'Hi There', 'many, many,     many words', 'Well, (#&$,"?/<!>.@%^*'].each do |theMark|
    it "recognizes mark only (#{theMark})" do
      answer = GradebookLoader.parse_mark_cell(theMark)
      expect(answer[:mark]).to eq theMark
      expect(answer[:late]).to be_nil
      expect(answer[:comment]).to be_nil
    end
  end # each

  it "strips spaces from mark when given mark only" do
    theMark = '    Hello, World!      '
    answer = GradebookLoader.parse_mark_cell(theMark)
      expect(answer[:mark]).to eq 'Hello, World!'
      expect(answer[:late]).to be_nil
      expect(answer[:comment]).to be_nil
  end

  ['mark|6', 'm.|17', 'm a r k | 43', '.|4213', '. | 4213     '].each do |value|
    it "recognizes mark and late days (#{value})" do
      parts = value.split('|')
      expect(parts.length).to eq 2

      answer = GradebookLoader.parse_mark_cell(value)
      expect(answer[:mark]).to eq parts.first.strip
      expect(answer[:late]).to eq parts.last.strip.to_i
      expect(answer[:comment]).to be_nil
    end #it
  end # each

  it "returns error state if mark is empty but days late present" do
    answer = GradebookLoader.parse_mark_cell("|44")    
    verify_error(answer)
  end

  it "returns error state if mark is whitespace only but days late present" do
    answer = GradebookLoader.parse_mark_cell("       |44")    
    verify_error(answer)
  end

  ['mark|4 5', 'mark|4 5 6', 'mark| 4 4  44   '].each do |value|
    it "returns error state if days late contains multiple integers (#{value})" do
      answer = GradebookLoader.parse_mark_cell(value)    
      verify_error(answer)
    end
  end

  ['mark|4 five', 'mark|five', 'mark|4.334', 'mark|4th', 'mark|m4'].each do |value|
    it "returns error state if days late contains non-integers (#{value})" do
      answer = GradebookLoader.parse_mark_cell(value)    
      verify_error(answer)
    end
  end

  it "recognizes mark and comment" do
    answer = GradebookLoader.parse_mark_cell("mark;the comment")
    expect(answer[:mark]).to eq 'mark'
    expect(answer[:late]).to be_nil
    expect(answer[:comment]).to eq 'the comment'
  end  

  it "recognizes mark and comment" do
    answer = GradebookLoader.parse_mark_cell("mark;the comment")
    expect(answer[:mark]).to eq 'mark'
    expect(answer[:late]).to be_nil
    expect(answer[:comment]).to eq 'the comment'
  end 

  it "returns error state if comment only" do
    answer = GradebookLoader.parse_mark_cell(";forescore and seven years ago")    
    verify_error(answer)
  end

  it "returns error state if mark is whitespace only but comment present" do
    answer = GradebookLoader.parse_mark_cell("       ;forescore and seven years ago")    
    verify_error(answer)
  end

  it "parses mark, late days and comment" do
    answer = GradebookLoader.parse_mark_cell("the mark|71;and a comment")
    expect(answer[:mark]).to eq 'the mark'
    expect(answer[:late]).to eq 71
    expect(answer[:comment]).to eq 'and a comment'
  end

  it "strips whitespace from all three fields." do 
    answer = GradebookLoader.parse_mark_cell("   the mark    |  5  ;     and a comment   ")
    expect(answer[:mark]).to eq 'the mark'
    expect(answer[:late]).to eq 5
    expect(answer[:comment]).to eq 'and a comment'
  end

end # describe