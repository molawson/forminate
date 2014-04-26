module Forminate
  class AssociationBuilder
    def initialize(name, attrs)
      @name = name
      @attrs = attrs
    end

    def build
      if primary_key
        object = klass.find(primary_key)
        object.assign_attributes(association_attributes)
        object
      else
        klass.new(association_attributes)
      end
    end

    private

    attr_reader :name, :attrs

    def klass
      name.to_s.classify.constantize
    end

    def prefix
      "#{name}_"
    end

    def primary_key
      return unless klass.respond_to?(:primary_key)

      attrs["#{name}_#{klass.primary_key}".to_sym]
    end

    def association_attributes
      relevant_attributes = attrs.select { |k, _| k =~ /^#{prefix}/ }
      relevant_attributes.each_with_object({}) do |(name, definition), hash|
        new_key = name.to_s.sub(prefix, '').to_sym
        hash[new_key] = definition
      end
    end
  end
end
