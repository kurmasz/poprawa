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
    dirs = %w(andersl brodieb davisc ahmede floresc garciam hernani jacksonr kimjus leee martinp nelsonm ortizja patelj quinna)
    dirs.each do |dir|
      FileUtils.mkdir("#{output_dir}/#{dir}")
    end

    result = run_ghpr('--suppress-github', test_data("testWorkbook_clean_config.rb"))

    expect(result[:err].length).to eq 0
    expect(result[:out].length).to eq 3

    expect(result[:exit]).to eq Poprawa::ExitValues::SUCCESS
  end
end # describe
