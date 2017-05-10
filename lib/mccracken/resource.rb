module McCracken
  # Subclassing this to add {json:api} models to your application
  class Resource
    extend Forwardable
    attr_reader :document
    attr_reader :attributes

    # @example Given a McCracken::Document
    #   document = McCracken::Document.new(jsonapi_hash)
    #   Person.new(document)
    #
    # @example Given an attributes hash
    #   Person.new(first_name: "Chauncy", last_name: "Vunderboot")
    #
    # @param [Hash,McCracken::Document] attrs
    def initialize(attrs = {})
      @document = if attrs.is_a?(McCracken::Document)
                    attrs
                  else
                    McCracken::Document.new(
                      data: {
                        type: self.class.type,
                        id: attrs.delete(:id),
                        attributes: attrs
                      }
                    )
                  end

      initialize_attrs
    end

    def id
      return nil if document.id.nil?
      @id ||= self.class.format_id(document.id)
    end

    def initialize_attrs
      @attributes = @document.attributes.clone
      self.class.schema.each do |name, attribute|
        casted_value = attribute.process(@attributes[name])
        @attributes[name] = casted_value
      end
    end

    def persisted?
      !id.nil?
    end

    def destroy
      document.destroy(agent)
    end

    def save
      @document = document.save(agent)
      !errors?
    end

    # @return [Array<Hash>] array of JSON API errors
    def errors
      document.errors
    end

    def errors?
      document.errors.any?
    end

    # @return [McCracken::Agent] a new {McCracken::Agent} instance
    def agent
      self.class.mccracken.agent
    end

    def serialized_attributes
      serialized_attrs = {}
      self.class.schema.each do |name, attribute|
        serialized_value = attribute.serialize(@attributes[name])
        serialized_attrs[name] = serialized_value
      end
      serialized_attrs
    end

    def ==(other)
      return false unless other

      if other.class.respond_to?(:type)
        self.class.type == other.class.type && id == other.id
      else
        false
      end
    end

    class << self
      def inherited(subclass)
        subclass.type = subclass.to_s.tableize.to_sym if subclass.to_s.respond_to?(:tableize)
      end

      # rubocop:disable Style/TrivialAccessors
      def key_type(type)
        @key_type = type
      end

      def format_id(id)
        case @key_type
        when :integer, nil
          id.to_i
        when :string
          id.to_s
        when Proc
          @key_type.call(id)
        end
      end

      def schema
        @schema ||= {}
      end

      def attribute(attribute_name, cast_type, **options)
        schema[attribute_name] = McCracken::Attribute.new(attribute_name, cast_type, options)

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attribute_name}
            @attributes[:#{attribute_name}]
          end
        RUBY

        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{attribute_name}=(val)
            document.attributes[:#{attribute_name}] = self.class.schema[:#{attribute_name}].serialize(val)
            @attributes[:#{attribute_name}] = val
          end
        RUBY
      end

      # rubocop:disable Style/PredicateName
      def has_one(relation_name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{relation_name}
            return @_#{relation_name}_relationship if @_#{relation_name}_relationship
            related_document = document.relationship(:#{relation_name})
            @_#{relation_name}_relationship = McCracken.factory(related_document)
          end
        RUBY
      end

      def has_many(relation_name)
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{relation_name}
            return @_#{relation_name}_relationship if @_#{relation_name}_relationship
            documents  = document.relationship(:#{relation_name})
            collection = McCracken::Collection.new(documents.map{ |doc| McCracken.factory(doc) })
            @_#{relation_name}_relationship = collection
          end
        RUBY
      end

      def mccracken_initializer(document)
        new(document)
      end

      def mccracken
        return @mccracken if @mccracken
        @mccracken = McCracken::Client.new
        @mccracken
      end

      # Set the JSONAPI type
      def type=(type)
        McCracken.register_type(type, self)
        mccracken.type = type
      end

      # Get the JSONAPI type
      def type
        mccracken.type
      end

      # Overwrite Connection#fields delegator to allow for passing an array of fields
      # @example
      #   Cat.fields(:name, :favorite_toy) #=> Query(fields[cats]=name,favorite_toy)
      #   Cat.fields(name, owner: [:name]) #=> Query(fields[cats]=name&fields[people]=name)
      def fields(*args)
        hash_fields = args.last.is_a?(Hash) ? args.pop : {}
        hash_fields[type] = args if args.any?
        mccracken.fields(hash_fields)
      end

      %i[include sort filter fetch fetch_from find page].each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{method}(*args)
            mccracken.#{method}(*args)
          end
        RUBY
      end
    end
  end
end
