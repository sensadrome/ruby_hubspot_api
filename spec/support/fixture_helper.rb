# frozen_string_literal: true

module FixtureHelper
  def load_json(name)
    file_path = File.join('spec', 'fixtures', "#{name}.json")
    JSON.parse(File.read(file_path))
  end
end

RSpec.configure do |config|
  config.include FixtureHelper
end
