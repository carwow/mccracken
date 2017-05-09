module McCracken
  # The query building used to construct and chain API queries
  class Query
    attr_reader :values

    # Description of method
    #
    # @param [McCracken::Client] client
    def initialize(client = nil)
      @client   = client
      @headers  = {}
      @values = {
        include: [],
        fields:  [],
        filter:  [],
        sort:    [],
        page:    {}
      }
    end

    def fetch
      raise McCracken::ClientNotSet, 'Client was not set. Query#new(client)' unless @client
      response = @client.agent.get(params: to_params, headers: @headers)
      ResponseMapper.new(response.body).collection
    end

    # Allow fetching from a custom endpoint
    #
    # @param [#to_s] path to custom endpoint off of resource
    # @option [Boolean] collection: true does this endpoint return a collection or a single resource
    def fetch_from(endpoint, collection: true)
      raise McCracken::ClientNotSet, 'Client was not set. Query#new(client)' unless @client
      path = [@client.agent.negotiate_path, endpoint.gsub(%r{^/}, '')].join('/')
      response = @client.agent.get(path: path, params: to_params, headers: @headers)
      ResponseMapper.new(response.body).send(collection ? :collection : :resource)
    end

    def find(id)
      raise McCracken::ClientNotSet, 'Client was not set. Query#new(client)' unless @client
      response = @client.agent.get(id: id, params: to_params, headers: @headers)
      ResponseMapper.new(response.body).resource
    end

    # @return [String] query as a query string
    def to_query_string
      Faraday::Utils.build_nested_query(to_params)
    end

    def to_s
      to_query_string
    end

    def to_params
      str = {}
      str[:filter]  = filter_to_query_value unless @values[:filter].empty?
      str[:fields]  = fields_to_query_value unless @values[:fields].empty?
      str[:include] = include_to_query_value unless @values[:include].empty?
      str[:sort]    = sort_to_query_value unless @values[:sort].empty?
      str[:page]    = @values[:page] unless @values[:page].empty?
      str
    end

    # Chainably set page options
    #
    # @example set a limit and offset
    #   McCracken::Query.new.page(limit: 10, offset: 5)
    #
    # @example set a size and number
    #   McCracken::Query.new.page(size: 10, number: 5)
    #
    # @return [McCracken::Query] self for chaining queries
    def page(opts = {})
      @values[:page].merge!(opts)
      self
    end

    # Chainably set headers
    #
    # @example set a header
    #   McCracken::Query.new.headers("X-API-TOKEN" => "banana")
    #
    # @example set headers
    #   McCracken::Query.new.headers("X-API-TOKEN" => "banana", "X-API-VERSION" => "1.3")
    #
    # @return [McCracken::Query] self for chaining queries
    def headers(opts = {})
      @headers.merge!(opts)
      self
    end

    # Chainably include related resources.
    #
    # @example including a resource
    #   McCracken::Query.new.include(:user)
    #
    # @example including a related resource
    #   McCracken::Query.new.include("user.addresses")
    #
    # @example including multiple resources
    #   McCracken::Query.new.include("user.addresses", "user.images")
    #
    # @param [Array<String,Symbol>] *args relationships to include
    # @return [McCracken::Query] self for chaining queries
    #
    # @see http://jsonapi.org/format/#fetching-includes JSON API Including Relationships
    def include(*args)
      @values[:include] += args
      self
    end

    # Chainably sort results
    # @note Default order is ascending
    #
    # @example sorting by a single field
    #   Munsun::Query.new.sort(:created_at)
    #
    # @example sorting by a multiple fields
    #   Munsun::Query.new.sort(:created_at, :age)
    #
    # @example specifying sort direction
    #   Munsun::Query.new.sort(:created_at, age: :desc)
    #
    # @example specifying sort direction
    #   Munsun::Query.new.sort(score: :desc, :created_at)
    #
    # @param [Hash<Symbol,Symbol>, Symbol] *args fields to sort by
    # @return [McCracken::Query] self for chaining queries
    #
    # @see http://jsonapi.org/format/#fetching-sorting JSON API Sorting Spec
    def sort(*args)
      validate_sort_args(args.select { |arg| arg.is_a?(Hash) })
      @values[:sort] += args
      self
    end

    # Hash resouce_name: [array of attribs]
    def fields(*args)
      @values[:fields] += args
      self
    end

    def filter(*args)
      @values[:filter] += args
      self
    end

    protected

    def sort_to_query_value
      @values[:sort].map do |item|
        if item.is_a?(Hash)
          item.to_a.map do |name, dir|
            dir.to_sym == :desc ? "-#{name}" : name.to_s
          end
        else
          item.to_s
        end
      end.join(',')
    end

    def fields_to_query_value
      values = @values[:fields].each_with_object({}) do |hash_arg, acc|
        hash_arg.each do |k, v|
          acc[k] ||= []
          v.is_a?(Array) ? acc[k] += v : acc[k] << v
          acc[k].map(&:to_s).uniq!
        end
      end
      values.map { |k, v| [k, v.join(',')] }.to_h
    end

    def include_to_query_value
      @values[:include].map(&:to_s).sort.join(',')
    end

    # Since the filter param's format isn't specified in the [spec](http://jsonapi.org/format/#fetching-filtering)
    # this implemenation uses (JSONAPI::Resource's implementation](https://github.com/cerebris/jsonapi-resources#filters)
    #
    # To override, implement your own CustomQuery inheriting from {McCracken::Query}
    # {McCracken::Client} takes a Query class to use. This method could be overriden
    # in your custom class
    #
    # @example Custom Query Builder
    #   class MyBuilder < McCracken::Query
    #     def filter_to_query_value
    #       # ... your fancier logic
    #     end
    #   end
    #
    #   class Article
    #     def self.mccracken
    #       return @mccracken if @mccracken
    #       @mccracken = McCracken::Client.new(
    #         query_builder: MyQuery,
    #         path: 'products'
    #       )
    #     end
    #   end
    #
    def filter_to_query_value
      values = @values[:filter].each_with_object({}) do |hash_arg, acc|
        hash_arg.each do |k, v|
          acc[k] ||= []
          v.is_a?(Array) ? acc[k] += v : acc[k] << v
          acc[k].uniq!
        end
      end
      values.map { |k, v| [k, v.join(',')] }.to_h
    end

    def validate_sort_args(hashes)
      hashes.each do |hash|
        hash.each do |_k, v|
          unless %i[desc asc].include?(v.to_sym)
            raise McCracken::UnsupportedSortDirectionError,
                  "Unknown direction '#{v}'. Use :asc or :desc"
          end
        end
      end
    end
  end
end
