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

describe "gh_progress_report writing" do

  it "places reports in each student's github repo" do
    output_dir = test_output("tw_clean")

    # Clean the output directory
    clean_dir(output_dir)

    # Create necessary student directories
    dirs = %w(lellaAnderson brodieb davisc Ahmed734 flocar macg Issac93 Rohan JustinKim elee pam3 nelsonm ortizzz JaggerP quinna)
    dirs.each { |dir| FileUtils.mkdir("#{output_dir}/#{dir}") }

    result = run_ghpr('--suppress-github', test_data("testWorkbook_config.rb"))

    expect(result[:err].length).to eq 0
    expect(result[:out].length).to eq 0

    dirs.each { |dir| expect(File.exist?("#{output_dir}/#{dir}/README.md")).to be true}

    expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
  end
end # describe
