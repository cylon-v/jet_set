require 'jet_set/validation_error'

module JetSet
  # Optional validation decorator. Adds validation logic to pure Ruby objects.
  module Validations
    # The method runs all validations declared in the model
    def validate!
      validations = self.class.class_variable_defined?(:@@validations) ? self.class.class_variable_get(:@@validations) : {}
      attributes = validations.keys
      invalid_items = []

      attributes.each do |attribute|
        attribute_validations = validations[attribute] || []

        error = nil
        attribute_validations.each do |validation|
          value = instance_variable_get("@#{attribute}")
          if validation[:func].call(value) == false
            error = validation[:message]
            break
          end
        end
        invalid_items << {"#{attribute}": error} if error
      end

      raise ValidationError.new("#{self.class.name} is invalid", invalid_items) if invalid_items.length > 0
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Adds a validation to an attribute of the entity
      # Parameters:
      #   +attribute_name+:: attribute name
      #   +message+:: message that will be shown if given attribute is invalid
      #   +func+:: boolean proc with a check for validity
      def validate(attribute_name, message, func)
        validations = self.class_variable_defined?(:@@validations) ? self.class_variable_get(:@@validations) : {}
        validations[attribute_name] ||= []
        validations[attribute_name] << {func: func, message: message}
        self.class_variable_set(:@@validations, validations)
      end
    end
  end
end
