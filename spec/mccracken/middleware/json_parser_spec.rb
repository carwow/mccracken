require 'spec_helper'

describe McCracken::Middleware::JsonParser, type: :response do
  let(:document) { response_body(:albums_include_artist) }

  let(:middleware) do
    described_class.new(lambda { |env|
      Faraday::Response.new(env)
    })
  end

  def faraday_env(body)
    env = {
      body: body, request: {},
      request_headers: Faraday::Utils::Headers.new({}),
      response_headers: Faraday::Utils::Headers.new({})
    }
    env[:response_headers]['content-type'] = 'application/vnd.api+json'
    env
  end

  context 'when the body is present' do
    it 'parses the body as JSON' do
      env = faraday_env(document)
      body = middleware.call(env).env.body

      expect(body).to match JSON.parse(document, symbolize_names: true)
    end
  end

  context 'when the body is empty' do
    it 'returns an empty hash' do
      env = faraday_env('')
      body = middleware.call(env).env.body
      expect(body).to eq({})
    end
  end
end
