module ActiveModel
  class Validator
    # To make use of validators present on associated object, we need to be
    # able to specify the original object that a given validator came from.
    attr_accessor :target_object
  end
end

module Forminate
  # This module makes Forminate work with bcardarella's client_side_validations
  # gem (https://github.com/bcardarella/client_side_validations).
  #
  # The majority of the methods contained here are overrides or alternative
  # versions of methods in the client_side_validations gem. For the most part,
  # they follow the shape and ideas of the original implementation, usually adding
  # the ability to send messages to an associated object rather than the Forminate
  # object itself.
  module ClientSideValidations
    extend ActiveSupport::Concern

    # Where the magic happens. This overrides the client_side_validations gem's
    # method of the same name, using Forminate's #association_validators rather
    # than ActiveModel's _validators method. It still calls super so that it
    # includes validations placed directly on the Forminate object.
    def client_side_validation_hash(force = nil)
      hash = super
      assoc_hash = association_validators.reduce({}) do |assoc_hash, (attr, validators)|
        unless [nil, :block].include?(attr)

          validator_hash = validators.reduce(Hash.new { |h,k| h[k] = []}) do |kind_hash, validator|
            model = validator.target_object
            model_pattern = /^#{model.class.name.underscore}_/
            target_attr = attr.to_s.sub(model_pattern, '').to_sym

            if force.is_a? Hash
              relevant_force = force.select { |k, v| k.to_s.match model_pattern }
              assoc_force = relevant_force.reduce({}) do |assoc_force, (key, value)|
                key = key.to_s.sub(model_pattern, '').to_sym
                assoc_force.merge({ key => value })
              end
            else
              assoc_force = force
            end

            if _can_use_for_client_side_validation?(model, target_attr, validator, assoc_force)
              if client_side_hash = validator.client_side_hash(model, target_attr, extract_force_option(target_attr, assoc_force))
                kind_hash[validator.kind] << client_side_hash.except(:on, :if, :unless)
              end
            end

            kind_hash
          end

          if validator_hash.present?
            assoc_hash.merge!(attr => validator_hash)
          else
            assoc_hash
          end
        else
          assoc_hash
        end
      end
      hash.merge assoc_hash
    end

    private

    # Constructs the associated validators for use with client_side_validations.
    # This is meant to mimic ActiveModel's #_validators method that the
    # client_side_validations gem relies on for construction the client side
    # validation hash.
    def association_validators
      associations.reduce({}) do |assoc_validators, (name, object)|
        if validate_assoc?(name) && object.respond_to?(:_validators)
          object._validators.each do |attr, validators|
            new_validators = validators.reduce([]) do |new_validators, validator|
              new_validator = validator.dup
              new_validator.target_object = object
              new_validators << new_validator
            end
            assoc_validators["#{name}_#{attr}".to_sym] = new_validators
          end
        end
        assoc_validators
      end
    end

    # Alternative version of the client_side_validation gem's
    # #can_use_for_client_side_validation? method, allowing the target 'model'
    # to be passed in as an argument.
    def _can_use_for_client_side_validation?(model, attr, validator, force)
      if validator_turned_off?(attr, validator, force)
        result = false
      else
        result = ((model.respond_to?(:new_record?) && validator.options[:on] == (model.new_record? ? :create : :update)) || validator.options[:on].nil?)
        result = result && validator.kind != :block

        if validator.options[:if] || validator.options[:unless]
          if result = can_force_validator?(attr, validator, force)
            if validator.options[:if]
              result = result && _run_conditional(model, validator.options[:if])
            end
            if validator.options[:unless]
              result = result && !_run_conditional(model, validator.options[:unless])
            end
          end
        end
      end

      result
    end

    # Alternative version of the client_side_validation gem's #run_conditional
    # method, allowing the target 'model' to be passed in as an argument.
    def _run_conditional(model, method_name_or_proc)
      case method_name_or_proc
      when Proc
        method_name_or_proc.call(model)
      else
        model.send(method_name_or_proc)
      end
    end
  end
end
