require 'json'
require 'cgi'
require 'faraday'
require 'faraday_middleware'
require 'bigdecimal'

require "mccracken/version"
require 'mccracken/agent'
require 'mccracken/attribute'
require "mccracken/client"
require 'mccracken/collection'
require 'mccracken/connection'
require 'mccracken/document'
require 'mccracken/key_formatter'
require "mccracken/middleware/encode_json_api"
require "mccracken/middleware/json_parser"
require 'mccracken/resource'
require 'mccracken/response_mapper'
require 'mccracken/query'

module McCracken
  class Error < StandardError; end;
  class UnsupportedSortDirectionError < McCracken::Error; end;
  class UnrecognizedKeyFormatter < McCracken::Error; end;
  class RelationshipNotIncludedError < McCracken::Error; end;
  class RelationshipNotFound < McCracken::Error; end;
  class ClientNotSet < McCracken::Error; end;
  @registered_types = {}

  class << self
    # Transforms a JSONAPI hash into a McCracken::Document, McCracken::Resource, or arbitrary class
    # @param [McCracken::Document,Hash] document to transform
    # @return [McCracken::Document,~McCracken::Resource]
    def factory(document)
      document = McCracken::Document.new(document) if document.is_a?(Hash)
      klass    = McCracken.lookup_type(document.type)

      if klass && klass.respond_to?(:mccracken_initializer)
        klass.mccracken_initializer(document)
      else
        document
      end
    end

    # Configure the default connection.
    #
    # @param [Hash] opts {McCracken::Connection} configuration options
    # @param [Proc] block to yield to Faraday::Connection
    # @return [McCracken::Connection] the default connection

    # @see https://github.com/lostisland/faraday/blob/master/lib/faraday/connection.rb Faraday::Connection
    # @see McCracken::Connection
    def configure(opts={}, &block)
      @default_connection = McCracken::Connection.new(opts, &block)
    end

    # The default connection
    #
    # @return [McCracken::Connection, nil] the default connection if configured
    def default_connection
      defined?(@default_connection) ? @default_connection : nil
    end

    # Register a JSON Spec resource type to a class
    # This is used in Faraday response middleware to package the JSON into a domain model
    #
    # @example Mapping a type
    #   McCracken.register_type("addresses", Address)
    #
    # @param [#to_sym] type JSON Spec type
    # @param [Class] klass to map to
    def register_type(type, klass)
      @registered_types[type.to_sym] = klass
    end

    # Lookup a class by JSON Spec type name
    #
    # @param [#to_sym] type JSON Spec type
    # @return [Class] domain model
    def lookup_type(type)
      @registered_types[type.to_sym]
    end
  end
end
