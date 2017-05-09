$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'coveralls'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/.bundle/'
end

require 'webmock/rspec'
require 'pry-byebug' unless defined?(JRUBY_VERSION)

require 'mccracken'

require 'support/macros/json_api_document_macros'
require 'support/macros/stub_request_macros'
require 'support/matchers/have_attr_accessor'
require 'support/matchers/have_data'

McCracken.configure url: 'http://api.example.com'

Dir['spec/support/app/*'].each { |f| load f }
WebMock.disable_net_connect!

RSpec.configure do |c|
  c.include McCracken::RSpec::Macros::JsonApiDocumentMacros
  c.include McCracken::RSpec::Macros::StubRequestMacros

  c.before(:each) do
    McCracken.configure url: 'http://api.example.com'
  end
end
