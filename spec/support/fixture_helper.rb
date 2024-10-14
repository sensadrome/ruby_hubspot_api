# frozen_string_literal: true

module FixtureHelper
  def load_json(name)
    file_path = File.join('spec', 'fixtures', "#{name}.json")
    erb_template = ERB.new(File.read(file_path))
    json_string = erb_template.result(binding)
    JSON.parse(json_string)
  end
end

RSpec.configure do |config|
  config.include FixtureHelper
end
