require 'json'
require 'cgi'
require 'faraday'
require 'faraday_middleware'

require "munson/version"

require "munson/middleware/encode_json_api"
require "munson/middleware/json_parser"

require 'munson/collection'
require 'munson/paginator'
require 'munson/response_mapper'
require 'munson/query_builder'
require 'munson/connection'
require 'munson/agent'
require 'munson/resource'

module Munson
  class Error < StandardError; end;
  class UnsupportedSortDirectionError < Munson::Error; end;
  class PaginatorNotSet < Munson::Error; end;
  class AgentNotSet < Munson::Error; end;

  @registered_types = {}
  @registered_paginators = {}

  class << self
    # Configure the default connection.
    #
    # @param [Hash] opts {Munson::Connection} configuration options
    # @param [Proc] block to yield to Faraday::Connection
    # @return [Munson::Connection] the default connection

    # @see https://github.com/lostisland/faraday/blob/master/lib/faraday/connection.rb Faraday::Connection
    # @see Munson::Connection
    def configure(opts={}, &block)
      @default_connection = Munson::Connection.new(opts, &block)
    end

    # The default connection
    #
    # @return [Munson::Connection, nil] the default connection if configured
    def default_connection
      defined?(@default_connection) ? @default_connection : nil
    end

    # Register a JSON Spec resource type to a class
    # This is used in Faraday response middleware to package the JSON into a domain model
    #
    # @example Mapping a type
    #   Munson.register_type("addresses", Address)
    #
    # @param [#to_sym] type JSON Spec type
    # @param [Class] klass to map to
    def register_type(type, klass)
      @registered_types[type.to_sym] = klass
    end

    def register_paginator(name, klass)
      @registered_paginators[name.to_sym] = klass
    end

    def lookup_paginator(name)
      @registered_paginators[name.to_sym]
    end

    # Lookup a class by JSON Spec type name
    #
    # @param [#to_sym] type JSON Spec type
    # @return [Class] domain model
    def lookup_type(type)
      @registered_types[type.to_sym]
    end

    # @private
    def flush_types!
      @registered_types = {}
    end
  end
end
