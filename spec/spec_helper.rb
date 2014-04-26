require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'bundler/setup'
require 'forminate'

# Requires supporting files in spec/support/
Dir["#{File.dirname(__FILE__)}/support/*.rb"].each { |file| require file }
