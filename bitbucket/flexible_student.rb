#####################################################################################
#
# Flexible Student
#
# Holds personal and grade data for one student. 
# Tries to guess values of keys.       
#
# (c) 2022 Zachary Kurmas
######################################################################################

class FlexibleStudent < Student
   
    attr_reader :info
  
    def fname 
      return @info[:fname] if @info.has_key?(:fname)
      use_key = nil
      @info.each do |key, value|
        use_key = key if key.downcase =~ /f.*name/
        use_key = key if !use_key && key.downcase =~ /first/
      end
      return @info[use_key] unless use_key.nil?


      puts "Error! Can't find key that likely represents a first name. #{@info.keys.inspect}"
      exit      
    end

    def lname 
      return @info[:lname] if @info.has_key?(:lname)

      use_key = nil
      @info.each do |key, value|
        use_key = key if key.downcase =~ /l.*name/
        use_key = key if !use_key && key.downcase =~ /last/
      end
      return @info[use_key] unless use_key.nil?

      puts "Error! Can't find key that likely represents a last name. #{@info.keys.inspect}"
      exit      
    end
  end
