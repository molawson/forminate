require 'forminate/version'

require 'active_support/concern'
require 'active_attr'

require 'forminate/association_definition'

module Forminate
  extend ActiveSupport::Concern
  include ActiveAttr::Model

  included do
    validate do
      associations.each do |name, object|
        next unless validate_assoc?(name) && object.respond_to?(:invalid?) && object.invalid?

        object.errors.each do |field, messages|
          errors["#{name}_#{field}".to_sym] = messages
        end
      end
    end
  end

  module ClassMethods
    def attributes_for(name, options = {})
      define_association(AssociationDefinition.new(name, options))
    end

    def association_names
      @association_names ||= []
    end

    def association_validations
      @association_validations ||= {}
    end

    private

    def define_association(assoc)
      assoc.attributes.each { |attr| define_attribute(attr, assoc.name) }
      association_names << assoc.name
      association_validations[assoc.name] = assoc.validation_condition
      send(:attr_accessor, assoc.name)
    end

    def define_attribute(attr, assoc_name)
      ActiveAttr::AttributeDefinition.new("#{assoc_name}_#{attr}").tap do |attribute_definition|
        attribute_name = attribute_definition.name.to_s
        attributes[attribute_name] = attribute_definition
      end
      define_attribute_reader(attr, assoc_name)
      define_attribute_writer(attr, assoc_name)
    end

    def define_attribute_reader(attr, assoc_name)
      define_method("#{assoc_name}_#{attr}") do
        send(assoc_name.to_sym).send(attr.to_sym)
      end
    end

    def define_attribute_writer(attr, assoc_name)
      define_method("#{assoc_name}_#{attr}=") do |value|
        send(assoc_name.to_sym).send("#{attr}=".to_sym, value)
      end
    end
  end

  def initialize(attributes = {})
    build_associations(attributes)
    super
  end

  def persisted?
    false
  end

  def association_names
    self.class.association_names
  end

  def associations
    Hash[association_names.map { |name| [name, send(name)] }]
  end

  def save
    return false unless valid?

    before_save
    if defined? ActiveRecord
      ActiveRecord::Base.transaction { persist_associations }
    else
      persist_associations
    end
    self
  end

  def before_save
    # hook method
  end

  def method_missing(name, *args, &block)
    assoc, assoc_method_name = association_for_method(name)
    if assoc && assoc.respond_to?(assoc_method_name)
      assoc.send(assoc_method_name, *args)
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    assoc, assoc_method_name = association_for_method(name)
    if assoc && assoc.respond_to?(assoc_method_name)
      true
    else
      super
    end
  end

  private

  def build_associations(attributes)
    association_names.each do |association_name|
      association = build_association(association_name, attributes)
      instance_variable_set("@#{association_name}".to_sym, association)
    end
  end

  def build_association(name, attributes)
    association_attributes = attributes_for_association(name, attributes)
    klass = name.to_s.classify.constantize

    if klass.respond_to? :primary_key
      primary_key = attributes["#{name}_#{klass.primary_key}".to_sym]
    end

    if primary_key
      object = klass.find primary_key
      object.assign_attributes association_attributes
      object
    else
      klass.new association_attributes
    end
  end

  def attributes_for_association(association_name, attributes)
    prefix = "#{association_name}_"
    relevant_attributes = attributes.select { |k, v| k =~ /#{prefix}/ }
    relevant_attributes.reduce({}) do |hash, (name, definition)|
      new_key = name.to_s.sub(prefix, '').to_sym
      hash[new_key] = definition
      hash
    end
  end

  def persist_associations
    associations.each { |_, object| object.save if object.respond_to?(:save) }
  end

  def validate_assoc?(name)
    send(assoc_validation_filter_method(name))
  end

  def assoc_validation_filter_method(name)
    filter = self.class.association_validations.fetch(name, true)
    case filter
    when Symbol
      filter
    when TrueClass, FalseClass
      method_name = "validate_#{name}?".to_sym
      self.class.send(:define_method, method_name) { filter }
      method_name
    else
      fail NotImplementedError, 'The attributes_for :validate option can only take a symbol, true, or false'
    end
  end

  def association_for_method(name)
    assoc_name = association_names.find { |an| name.match(/^#{an}_/) }

    return unless assoc_name

    assoc_method_name = name.to_s.sub("#{assoc_name}_", '').to_sym
    assoc = send(assoc_name)
    return assoc, assoc_method_name
  end
end
