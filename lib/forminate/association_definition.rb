module Forminate
  class AssociationDefinition

    attr_reader :name

    def initialize(name, options = {})
      @name = name
      @options = options
    end

    def attributes
      name.to_s.classify.constantize.attribute_names
    end

    def validation_condition
      options.fetch(:validate) { true }
    end

    private

    attr_reader :options
  end
end
