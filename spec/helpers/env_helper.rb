##########################################################################################################
#
# Check whether RSpec is running in debug mode.
#
# (Debug mode prints the complete output of the program under test, instead of just listing failures)
#
# Author::    Zachary Kurmas
# Copyright:: (c) Zachary Kurmas 2017
#
##################################################################################################################
module EnvHelper

  # return true if the environment variable DEBUG indicates that debugging output is desired.   (Any value for DEBUG,
  # other than a case-insensitive 'false' or 'no' is considered a request for debug information.)
  def self.debug_mode?
    @debug_mode ||= ENV.key?('DEBUG') && (ENV['DEBUG'].casecmp('false') != 0) && (ENV['DEBUG'].casecmp('no') != 0)
  end

  # stop after first failure
  def self.fail_fast?
    @fail_fast ||= ENV.key?('FAIL_FAST')
  end

  # return true if the environment indicates Windows
  def self.windows?
    (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil
  end
end