module McCracken
  # The Client is a unified way of providing all {json:api} features to Resources
  class Client
    extend Forwardable
    def_delegators :query, :include, :sort, :filter, :fields, :fetch, :fetch_from, :page, :find
    def_delegators :connection, :url=, :url, :response_key_format, :response_key_format=

    attr_writer :path
    attr_writer :query_builder
    attr_accessor :type

    def initialize(opts = {})
      opts.each do |k, v|
        setter = "#{k}="
        send(setter, v) if respond_to?(setter)
      end
    end

    def query
      (@query_builder || Query).new(self)
    end

    def agent
      Agent.new(path, connection: connection)
    end

    def path
      @path || type.to_s
    end

    def configure
      yield(self)
      self
    end

    def connection
      @connection ||= McCracken.default_connection.clone
    end

    attr_writer :connection
  end
end
