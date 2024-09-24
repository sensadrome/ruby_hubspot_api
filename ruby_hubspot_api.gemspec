# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'hubspot/version'

# rubocop:disable Metrics/BlockLength
Gem::Specification.new do |spec|
  spec.name          = 'ruby_hubspot_api'
  spec.version       = Hubspot::VERSION
  spec.authors       = ['Simon Brook']
  spec.email         = ['simon@datanauts.co.uk']

  spec.summary = 'ruby_hubspot_api is an ORM-like wrapper for the Hubspot API'
  spec.description = 'ruby_hubspot_api is an ORM-like wrapper for v3 of the Hubspot API'
  spec.homepage = 'https://github.com/sensadrome/ruby_hubspot_api'
  spec.license = 'MIT'

  spec.required_ruby_version = '>= 2.5'

  # Prevent pushing this gem to RubyGems.org.
  # To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Define development dependencies
  spec.add_development_dependency 'rake', '~> 11.0'

  spec.add_dependency 'bundler', '~> 2.3', '< 3.0'
  spec.add_dependency 'dotenv', '~> 2.8', '< 3.0'
  spec.add_dependency 'pry', '~> 0.13', '< 1.0'
  spec.add_dependency 'pry-byebug', '~> 3.9', '< 4.0'
  spec.add_dependency 'rspec', '~> 3.13', '< 4.0'
  spec.add_dependency 'simplecov', '~> 0.22', '< 1.0'
  spec.add_dependency 'vcr', '~> 6.0', '< 7.0'
  spec.add_dependency 'webmock', '~> 3.23', '< 4.0'

  # Define runtime dependencies
  spec.add_runtime_dependency 'httparty', '~> 0.21', '< 1.0'
end
# rubocop:enable Metrics/BlockLength
