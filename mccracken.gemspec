# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mccracken/version'

Gem::Specification.new do |spec|
  spec.name          = 'mccracken'
  spec.version       = McCracken::VERSION
  spec.authors       = ['Jonathan Gnagy']
  spec.email         = ['jonathan.gnagy@gmail.com']

  spec.summary       = 'A JSON API Spec client for Ruby'
  spec.homepage      = 'http://github.com/jgnagy/mccracken'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday'
  spec.add_dependency 'faraday_middleware'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rspec-mocks'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-byebug' unless defined?(JRUBY_VERSION)
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'byebug' unless defined?(JRUBY_VERSION)
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'travis', '~> 1.8'
end
