require 'spec_helper'

describe McCracken do
  it 'has a version number' do
    expect(McCracken::VERSION).not_to be nil
  end

  pending '.factory' # .factory?

  describe '.configure' do
    it 'sets the default connection' do
      McCracken.configure url: 'http://example.com' do |c|
        c.use TestMiddleware
      end

      expect(McCracken.default_connection).to be_a(McCracken::Connection)
      expect(McCracken.default_connection.faraday.url_prefix.to_s).to eq 'http://example.com/'
    end
  end

  describe '.register_type' do
    it 'registers a JSON Spec resource type' do
      class Blog; end
      McCracken.register_type('blogs', Blog)

      expect(McCracken.lookup_type('blogs')).to be Blog
    end
  end
end
