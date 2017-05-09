module McCracken
  # Manages the process of converting JSON Object keys to Document attribute symbols
  class KeyFormatter
    # @param [Symbol] resource_key_format
    def initialize(resource_key_format)
      @format = resource_key_format
    end

    # Converts underscored keys to `format`
    def externalize(hash)
      deep_transform_keys(hash) do |key|
        if @format == :dasherize
          dasherize(key)
        elsif @format == :camelize
          camelize(key)
        else
          raise UnrecognizedKeyFormatter, <<-ERR
          No key formatter found for `#{@format}`.

          Valid :key_format values are `:camelize` and `:underscore`.
          You may also provide a hash of lambdas `{format:->(key){}, unformat:->(key){}}`
          ERR
        end
      end
    end

    # Converts keys formatted in `format` to underscore
    def internalize(hash)
      deep_transform_keys(hash) do |key|
        if @format == :dasherize
          undasherize(key)
        elsif @format == :camelize
          underscore(key)
        else
          raise UnrecognizedKeyFormatter, <<-ERR
          No key formatter found for `#{@format}`.

          Valid :key_format values are `:camelize` and `:underscore`.
          You may also provide a hash of lambdas `{format:->(key){}, unformat:->(key){}}`
          ERR
        end
      end
    end

    private

    def deep_transform_keys(hash, &block)
      result = {}
      hash.each do |key, value|
        result[yield(key)] = map_value(value, &block)
      end
      result
    end

    def map_value(value, &block)
      case value
      when Hash
        deep_transform_keys(value, &block)
      when Array
        value.map { |v| map_value(v, &block) }
      else
        value
      end
    end

    def camelize(key)
      string = key.to_s
      string = string.sub(/^(?:(?=\b|[A-Z_])|\w)/, &:downcase)
      string.gsub!(%r{(?:_|(/))([a-z\d]*)}i) do
        "#{Regexp.last_match(1)}#{Regexp.last_match(2).capitalize}"
      end
      string.to_sym
    end

    def underscore(camel_cased_word)
      return camel_cased_word unless camel_cased_word =~ /[A-Z-]|::/
      word = camel_cased_word.to_s
      word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2'.freeze)
      word.gsub!(/([a-z\d])([A-Z])/, '\1_\2'.freeze)
      word.tr!('-'.freeze, '_'.freeze)
      word.downcase!
      word.to_sym
    end

    def undasherize(key)
      key.to_s.tr('-'.freeze, '_'.freeze).to_sym
    end

    def dasherize(key)
      key.to_s.tr('_'.freeze, '-'.freeze).to_sym
    end
  end
end
