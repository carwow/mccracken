module McCracken
  # Maps JSONAPI Responses to ruby objects.
  #
  # @note
  #   When a JSONAPI collection (data: <Array>) is received it maps the response
  #   into multiple JSONAPI resource objects (data: <Hash>) and passes each to
  #   the #initialize_resource method so that each resource can act independently
  #   of the collection. JSONAPI collection are wrapped in a McCracken::Collection
  #   which will also contain metadata from the request
  #
  # @example Mapping an unregistered JSONAPI collection response
  #   json   = {
  #     data: [
  #       {id: 1, type: :cats, attributes: {name: 'Gorbypuff'}},
  #       {id: 1, type: :cats, attributes: {name: 'Grumpy Cat'}}
  #     ]
  #   }
  #
  #   mapper = ResponseMapper.new(json)
  #   mapper.collection #=>
  #   McCracken::Collection([
  #     {data: {id: 1, type: :cats, attributes: {name: 'Gorbypuff'}}},
  #     {data: {id: 1, type: :cats, attributes: {name: 'Grumpy Cat'}}
  #   ])
  #
  # @example Mapping a registered JSONAPI collection response
  #   json   = {
  #     data: [
  #       {id: 1, type: :cats, attributes: {name: 'Gorbypuff'}},
  #       {id: 1, type: :cats, attributes: {name: 'Grumpy Cat'}}
  #     ]
  #   }
  #   class Cat
  #     #... mccracken config
  #     def self.mccracken_initializer(resource)
  #       Cat.new(resource)
  #     end
  #
  #     def new(attribs)
  #       #do what you want
  #     end
  #   end
  #   McCracken.register_type(:cats, Cat)
  #
  #   mapper.collection #=> McCracken::Collection([cat1, cat2])
  #
  # ResourceMapper maps responses in 3 ways:
  # @example Mapping a McCracken::Resource
  #
  # @example Mapping a registered type
  #
  # @example Mapping an unregistered type
  #
  class ResponseMapper
    # @param [Hash] response_body jsonapi formatted hash
    def initialize(response_body)
      @body = response_body
    end

    # Moved top level keys to the collection
    # * errors: an array of error objects
    # * meta: a meta object that contains non-standard meta-information.
    # * jsonapi: an object describing the server's implementation
    # * links: a links object related to the primary data.
    def collection
      raise Exception, 'IMPLEMENT ERRORS JERK' if errors?
      raise McCracken::Error, 'Use ResponseMapper#resource on single resource' unless collection?

      # Make each item in :data its own document, stick included into that document
      records = @body[:data].each_with_object([]) do |resource, agg|
        json = { data: resource }
        json[:included] = @body[:included] if @body[:included]
        agg << json
      end

      Collection.new(
        records.map { |datum| McCracken.factory(datum) },
        meta:    @body[:meta],
        jsonapi: @body[:jsonapi],
        links:   @body[:links]
      )
    end

    def resource
      raise Exception, 'IMPLEMENT ERRORS JERK' if errors?
      raise McCracken::Error, 'Use ResponseMapper#collection on collections' unless resource?

      McCracken.factory(@body)
    end

    def jsonapi_resources
      data = collection? ? @body[:data] : [@body[:data]]
      included = @body[:included] || []
      (data + included)
    end

    private def errors?
      @body[:errors].is_a?(Array)
    end

    private def resource?
      @body[:data].is_a?(Hash)
    end

    private def collection?
      @body[:data].is_a?(Array)
    end
  end
end
