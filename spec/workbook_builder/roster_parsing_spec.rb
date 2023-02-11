#################################################################################################
#
# System/end-to-end tests for the workbook builder's roster parsing.
# (Note: The purpose of this file is not to verify that the workbook is build correctly,
# it is just to verify that errors and omissions in the .csv files are detected and reported.
# workbook_builder.rb verifies that the workbook is built correctly.)
#
# Author::    Zachary Kurmas
#
# Copyright:: (c) Zachary Kurmas 2023
#
##################################################################################################
require "spec_helper"
require "rubyXL"

describe "workbook parser roster parsing" do
  describe "(arbitrary csv)" do
  end

  describe "(BB classic)" do
    it "Complains if a last name is missing"

    it "Complains if a first name is missing"

    it "Complains if a username is missing"

    it "Complains if a Child Course ID is missing"

    it "Complains if a Child Course ID is not parsable"
  end # BB classic
end # describe workbook parser
