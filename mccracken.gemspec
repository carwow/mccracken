# frozen_string_literal: true

require_relative "lib/mccracken/version"

Gem::Specification.new do |spec|
  tag_version = "ruby-v#{McCracken::VERSION}"
  base_url = "https://github.com/carwow/mccracken/tree/#{tag_version}"

  spec.name = "mccracken"
  spec.version = McCracken::VERSION
  spec.authors = ["carwow"]
  spec.email = ["developers@carwow.co.uk"]
  spec.summary = "JSON:API client"

  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/carwow"
  spec.metadata["source_code_uri"] = base_url
  spec.metadata["homepage_uri"] = "#{base_url}/README.md"
  spec.metadata["changelog_uri"] = "#{base_url}/CHANGELOG.md"

  spec.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 1.3"
  spec.add_dependency "faraday_middleware", "~> 1.0"
  spec.add_dependency "zeitwerk", "~> 2.4"

  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.10"
  spec.add_development_dependency "rspec-mocks", "~> 3.10"
  spec.add_development_dependency "webmock", "~> 3.11"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "standard", "~> 0.12"
end
