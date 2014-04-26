require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'bundler/setup'
require 'forminate'

require 'active_record'
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
ActiveRecord::Schema.define do
  suppress_messages do
    create_table :dummy_users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
    end
  end
end

# Requires supporting files in spec/support/
Dir["#{File.dirname(__FILE__)}/support/*.rb"].each { |file| require file }
