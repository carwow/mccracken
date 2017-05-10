module McCracken
  # A layer of abstraction for managing higher-level actions on a connection
  class Agent
    # Creates a new McCracken::Agent
    #
    # @param [#to_s] path to JSON API Resource. Will be added to the Faraday::Connection base path
    # @param [McCracken::Connection] connection to use
    def initialize(path, connection: nil)
      @path       = path
      @connection = connection
    end

    # Connection that will be used for HTTP requests
    #
    # @return [McCracken::Connection] default or current connection
    def connection
      return @connection if @connection
      McCracken.default_connection
    end

    # JSON API Spec GET request
    #
    # @option [Hash,nil] params: nil query params
    # @option [String] path: nil path to GET, default Faraday::Connection url + Agent#default_path
    # @option [Hash] headers: nil HTTP Headers
    # @option [String,Fixnum] id: nil ID to append to @path (provided in #new) for resource.
    #   If :path and :id are both specified, :path wins
    # @return [Faraday::Response]
    def get(params: nil, path: nil, headers: nil, id: nil)
      connection.get(
        path: negotiate_path(path, id),
        params: params,
        headers: headers
      )
    end

    def negotiate_path(path = nil, id = nil)
      if path
        path
      elsif id
        [@path, id].join('/')
      else
        @path
      end
    end

    # JSON API Spec POST request
    #
    # @option [Hash,nil] body: {} query params
    # @option [String] path: nil path to GET,
    #   defaults to Faraday::Connection url + Agent#default_path
    # @option [Hash] headers: nil HTTP Headers
    # @option [Type] http_method: :post describe http_method: :post
    # @option [String,Fixnum] id: nil ID to append to default path when accessing a resource.
    #   If :path and :id are both specified, :path wins
    # @return [Faraday::Response]
    def post(body: {}, path: nil, headers: nil, http_method: :post, id: nil)
      connection.post(
        path: negotiate_path(path, id),
        body: body,
        headers: headers,
        http_method: http_method
      )
    end

    # JSON API Spec PATCH request
    #
    # @option [Hash,nil] body: nil query params
    # @option [String] path: nil path to GET,
    #   defaults to Faraday::Connection url + Agent#default_path
    # @option [Hash] headers: nil HTTP Headers
    # @option [String,Fixnum] id: nil ID to append to default path when accessing a resource.
    #   If :path and :id are both specified, :path wins
    # @return [Faraday::Response]
    def patch(body: nil, path: nil, headers: nil, id: nil)
      post(body: body, path: path, headers: headers, http_method: :patch, id: id)
    end

    # JSON API Spec PUT request
    #
    # @option [Hash,nil] body: nil query params
    # @option [String] path: nil path to GET,
    #   defaults to Faraday::Connection url + Agent#default_path
    # @option [Hash] headers: nil HTTP Headers
    # @option [String,Fixnum] id: nil ID to append to default path when accessing a resource.
    #   If :path and :id are both specified, :path wins
    # @return [Faraday::Response]
    def put(body: nil, path: nil, headers: nil, id: nil)
      post(body: body, path: path, headers: headers, http_method: :put, id: id)
    end

    # JSON API Spec DELETE request
    #
    # @option [Hash,nil] body: nil query params
    # @option [String] path: nil path to GET,
    #   defaults to Faraday::Connection url + Agent#default_path
    # @option [Hash] headers: nil HTTP Headers
    # @option [String,Fixnum] id: nil ID to append to default path when accessing a resource.
    #   If :path and :id are both specified, :path wins
    # @return [Faraday::Response]
    def delete(body: nil, path: nil, headers: nil, id: nil)
      post(body: body, path: path, headers: headers, http_method: :delete, id: id)
    end
  end
end
