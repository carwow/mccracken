module McCracken
  # ActiveRecord ActiveModel::Name compatibility methods
  class Resource
    def self.human
      i18n_key.humanize
    end

    def self.i18n_key
      name.split("::").last.underscore
    end

    def self.param_key
      singular_route_key.to_sym
    end

    def self.route_key
      singular_route_key.en.plural
    end

    def self.singular_route_key
      name.split("::").last.underscore
    end

    def model_name
      self.class
    end

    def new?
      id ? false : true
    end

    def to_model
      self
    end

    def to_key
      new? ? [] : [id]
    end

    def to_param
      new? ? nil : id.to_s
    end
  end
end
