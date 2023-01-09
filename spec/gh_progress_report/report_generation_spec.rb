#################################################################################################
#
# System/end-to-end tests for the gh_progress_report report generation
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2023
#
##################################################################################################
require "spec_helper"

describe "gh_progress_report generation" do
  before(:all) do
    unless File.exist?(gh_output('.git'))
      $stderr.puts "For these tests #{gh_output} must be a github directory"
      exit
    end
  end

  it "places reports in each student's github repo" do
    output_dir = gh_output("tw_clean")

    # Clean the output directory
    clean_dir(output_dir)

    # Create necessary student directories
    dirs = %w(andersl brodieb davisc ahmede floresc garciam hernani jacksonr kimjus leee martinp nelsonm ortizja patelj quinna)
    dirs.each do |dir|
      FileUtils.mkdir("#{output_dir}/#{dir}")
    end

    result = run_ghpr(test_data("testWorkbook_clean_config.rb"))

    expect(result[:err].length).to eq 0
    #  expect(result[:out].length).to eq 0

    expect(result[:exit]).to eq Poprawa::ExitValues::INVALID_PARAMETER
  end
end # describe
