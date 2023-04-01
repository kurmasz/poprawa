config = {  
    categories: [{
        title: "Learning Objectives",
        },
        {
        title: "Homework",
        },
        {
        title: "Projects",
    }]
  }

describe 'workbook_builder' do
    it "generates a new category key if not specified" do
        config[:categories].each do |category|
            unless category.has_key?(:key)
              category[:key] = category[:title].gsub(/\s+/, "_").downcase.to_sym
            end
        end
        
        expect(config[:categories][0][:key]).to eq :learning_objectives
        expect(config[:categories][1][:key]).to eq :homework
        expect(config[:categories][2][:key]).to eq :projects
    end

    it "generates a new category short name if not specified" do
        config[:categories].each do |category|
            unless category.has_key?(:short_title)
                category[:short_title] = category[:title].split.map(&:chr).join.upcase
              end
        end

        expect(config[:categories][0][:short_title]).to eq "LO"
        expect(config[:categories][1][:short_title]).to eq "H"
        expect(config[:categories][2][:short_title]).to eq "P"
    end
end