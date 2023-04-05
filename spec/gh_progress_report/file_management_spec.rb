#################################################################################################
#
# System/end-to-end tests for the gh_progress_report report writing
# (i.e., that the report is placed in the correct location)
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2023
#
##################################################################################################
require "spec_helper"

describe "gh_progress_report file management" do
  it "places reports and images in each student's github repo", slow: true do

    # Note: The output is the directory where the student repos are.
    # In production, this directory is often named "progress-report", 
    # but it doesn't have to be.
    output_dir = test_output("FilePlacementClean")
    
    # Clean the output directory
    clean_dir(output_dir)

    FileUtils.mkdir(base_output_dir) unless File.exist?(output_dir)
    
    # Create necessary student directories
    dirs = %w(lella98 brodieb davisc evah flores23 macg00 hernandi jacksonr kimj lelel pammartinez nelsonm oritzm JaggerP qunna)
    dirs.each { |dir| FileUtils.mkdir("#{output_dir}/#{dir}") }

    result = run_ghpr("--suppress-github", "--output=#{output_dir}", test_data("testWorkbook_config.rb"))

    expect(result[:err].length).to eq 0
    expect(result[:out].length).to eq 0

    dirs.each do |dir|
      expect(File.exist?("#{output_dir}/#{dir}/README.md")).to be true
      expect(File.exist?("#{output_dir}/#{dir}/LO.png")).to be true
      expect(File.exist?("#{output_dir}/#{dir}/H.png")).to be true
    end

    expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
  end

  context "with GitHub", github: true do

    before(:all) do
      unless File.exist?(gh_output(".git"))
        $stderr.puts "For these tests #{gh_output} must be a github directory"
        exit
      end
    end
  
    it "pushes updated reports to github", :github do

      output_dir = gh_output("PushGitHubReports")

      # Clean the output directory
      clean_dir(output_dir)

      FileUtils.mkdir(base_output_dir) unless File.exist?(output_dir)

      # Create necessary student directories
      dirs = %w(lellaAnderson brodieb davisc Ahmed734 flocar macg Issac93 Rohan JustinKim elee pam3 nelsonm ortizzz JaggerP quinna)
      dirs.each do |dir|
        FileUtils.mkdir("#{output_dir}/#{dir}")
      end

      result = run_ghpr(test_data("testWorkbook_config.rb"), "--output #{output_dir}")

      expect(result[:err].length).to eq 0
      #  expect(result[:out].length).to eq 0
      # TODO Verify that the github commands succeeded

      expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
    end
  end # end context
end # describe
