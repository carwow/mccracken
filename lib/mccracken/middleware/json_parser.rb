module McCracken
  module Middleware
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
        unless body.strip.empty?
          json = ::JSON.parse(body, symbolize_names: true)
          @key_formatter ? @key_formatter.internalize(json) : json
        else
          {}
        end
      end
    end
  end
end
Faraday::Response.register_middleware :"McCracken::Middleware::JsonParser" => McCracken::Middleware::JsonParser
