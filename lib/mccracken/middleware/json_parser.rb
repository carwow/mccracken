module McCracken
  module Middleware
    # A Faraday Middleware for parsing JSON parsing
    class JsonParser < Faraday::Response::Middleware
      def initialize(app, key_formatter = nil)
        super(app)
        @key_formatter = key_formatter
      end

      def call(request_env)
        @app.call(request_env).on_complete do |request_env|
          request_env[:body] = parse(request_env[:body])
        end
      end

      private

      def parse(body)
        if body.strip.empty?
          {}
        else
          json = ::JSON.parse(body, symbolize_names: true)
          @key_formatter ? @key_formatter.internalize(json) : json
        end
      end
    end
  end
end
