module McCracken
  module Middleware
    # A Faraday Middleware for performing {json:api} operations
    class EncodeJsonApi < Faraday::Middleware
      CONTENT_TYPE = "Content-Type".freeze
      ACCEPT = "Accept".freeze
      MIME_TYPE = "application/vnd.api+json".freeze
      USER_AGENT = "User-Agent".freeze

      def initialize(app, key_formatter = nil)
        super(app)
        @key_formatter = key_formatter
      end

      def call(env)
        env[:request_headers][USER_AGENT] = "McCracken v#{McCracken::VERSION}"
        env[:request_headers][ACCEPT] ||= MIME_TYPE
        match_content_type(env) do |data|
          env[:body] = encode data
        end
        @app.call env
      end

      def encode(data)
        json = @key_formatter ? @key_formatter.externalize(data) : data
        ::JSON.dump(json)
      end

      def match_content_type(env)
        return nil unless process_request?(env)
        env[:request_headers][CONTENT_TYPE] ||= MIME_TYPE
        yield env[:body] unless env[:body].respond_to?(:to_str)
      end

      def process_request?(env)
        type = request_type(env)
        has_body?(env) && (type.empty? || type == MIME_TYPE)
      end

      def has_body?(env)
        (body = env[:body]) && !(body.respond_to?(:to_str) && body.empty?)
      end

      def request_type(env)
        type = env[:request_headers][CONTENT_TYPE].to_s
        type = type.split(";", 2).first if type.index(";")
        type
      end
    end
  end
end
