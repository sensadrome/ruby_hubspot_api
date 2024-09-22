# frozen_string_literal: true

require 'bundler/setup'
require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
end

require 'dotenv/load'
require 'pry'
require 'pry-byebug'
require 'ruby_hubspot_api'
require 'vcr'
require 'webmock/rspec'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

RSPEC_ROOT = File.dirname(__FILE__)

Dir["#{RSPEC_ROOT}/support/**/*.rb"].sort.each { |f| require f }

# Require shared examples
Dir["#{RSPEC_ROOT}/shared_examples/**/*.rb"].sort.each { |f| require f }
