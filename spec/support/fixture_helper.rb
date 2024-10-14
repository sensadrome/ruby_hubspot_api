# frozen_string_literal: true

module FixtureHelper
  FILE_NOT_FOUND_MSG = 'Fixture not found: %<name>s'

  def load_json(name)
    erb_file_path = fixture_path("#{name}.json.erb")
    json_file_path = fixture_path("#{name}.json")

    json_string = if File.exist?(erb_file_path)
                    parse_erb(erb_file_path)
                  elsif File.exist?(json_file_path)
                    File.read(json_file_path)
                  else
                    raise format(FILE_NOT_FOUND_MSG, name: name)
                  end

    JSON.parse(json_string)
  end

  private

  def fixture_path(filename)
    File.join('spec', 'fixtures', filename)
  end

  def parse_erb(file_path)
    ERB.new(File.read(file_path)).result(binding)
  end
end

RSpec.configure do |config|
  config.include FixtureHelper
end
