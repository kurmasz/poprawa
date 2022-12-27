##################################################################################################
#
# spec_helper.rb
#
# Author::    Zachary Kurmas
# Copyright:: (c) Zachary Kurmas 2022
#
#
##################################################################################################

require 'poprawa/exit_values'

require 'helpers/env_helper'
require 'helpers/gradebook_runner'

RSpec.configure do |config|
  config.include GradebookRunner

  # By default, don't run the interactive specs
  config.filter_run_excluding interactive: true

  # Exclude these tests when running on windows.
  config.filter_run_excluding exclude_windows: true if EnvHelper.windows?

  # If we choose a different string later, then we need only make a single change here instead of
  # editing most of the examples.
  config.before(:example) { @test_error ='Test Error:' }
  config.before(:example) { @test_fail ='Failure:' }

  config.fail_fast = EnvHelper.fail_fast?
end

#
# Verifies that array contains at least one matching line
#
RSpec::Matchers.define :include_line_matching do |expected|
  match do |actual|
    actual.find { |line| line =~ expected }
  end

  failure_message do |actual|
    "expected #{actual} to include a line matching #{expected}"
  end
end
