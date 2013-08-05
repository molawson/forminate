require "forminate/version"

require 'active_support/concern'
require 'active_attr'

module Forminate
  extend ActiveSupport::Concern
  include ActiveAttr::Model

  included do
    validate do
      associations.each do |name, object|
        if should_validate_assoc?(name) && object.respond_to?(:invalid?) && object.invalid?
          object.errors.each do |field, messages|
            errors["#{name}_#{field}".to_sym] = messages
          end
        end
      end
    end
  end

  module ClassMethods
    def attributes_for(name, options = {})
      define_attributes name
      define_association name, options
    end

    def association_names
      @association_names ||= []
    end

    def association_validations
      @association_validations ||= {}
    end

    private

    def define_attributes(association_name)
      attributes = association_name.to_s.classify.constantize.attribute_names
      attributes.each { |attr| define_attribute(attr, association_name) }
    end

    def define_attribute(attr, assoc)
      ActiveAttr::AttributeDefinition.new("#{assoc}_#{attr}").tap do |attribute_definition|
        attribute_name = attribute_definition.name.to_s
        attributes[attribute_name] = attribute_definition
      end
      define_attribute_reader(attr, assoc)
      define_attribute_writer(attr, assoc)
    end

    def define_attribute_reader(attr, assoc)
      define_method("#{assoc}_#{attr}") do
        send(assoc.to_sym).send(attr.to_sym)
      end
    end

    def define_attribute_writer(attr, assoc)
      define_method("#{assoc}_#{attr}=") do |value|
        send(assoc.to_sym).send("#{attr}=".to_sym, value)
      end
    end

    def define_association(name, options = {})
      association_names << name
      should_validate = if options.has_key?(:validate)
                          options[:validate]
                        else
                          true
                        end
      association_validations[name] = should_validate
      send(:attr_accessor, name)
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
    associations.each do |name, object|
      object.save if object.respond_to? :save
    end
  end

  def should_validate_assoc?(name)
    method_name = assoc_validation_filter_method(name)
    send(method_name)
  end

  def assoc_validation_filter_method(name)
    filter = self.class.association_validations.fetch(name, true)
    method_name = "should_validate_#{name}?".to_sym
    case filter
    when Symbol
      filter
    when TrueClass, FalseClass
      self.class.send(:define_method, method_name) { filter }
      method_name
    else
      raise NotImplementedError, "The attributes_for :validate option can only take a symbol, true, or false"
    end
  end

  def association_for_method(name)
    assoc_name = association_names.find { |an| name.match /^#{an}_/ }
    if assoc_name
      assoc_method_name = name.to_s.sub("#{assoc_name}_", '').to_sym
      assoc = send(assoc_name)
      return assoc, assoc_method_name
    end
  end
end
