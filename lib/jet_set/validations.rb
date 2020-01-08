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
      #   +attribute_name+:: +Symbol+ attribute name
      #   +message+:: message that will be shown if given attribute is invalid
      #   +func+:: boolean proc with a check for validity
      def validate(attribute_name, message, func)
        validations = self.class_variable_defined?(:@@validations) ? self.class_variable_get(:@@validations) : {}
        validations[attribute_name] ||= []
        validations[attribute_name] << {func: func, message: message}
        self.class_variable_set(:@@validations, validations)
      end

      # Adds a presence validation to an attribute
      # Parameters:
      #   +attribute_name+:: an attribute name to validate
      def validate_presence(attribute_name)
        validate attribute_name, 'cannot be blank', -> (value) {!value.nil? && value != ''}
      end

      # Adds type validation to string attribute
      # Parameters:
      #   +attribute_name+:: an attribute name to validate
      #   +type+:: a type to check, possible values - :numeric|:string|:boolean
      def validate_type(attribute_name, type)
        unless [:numeric, :string, :boolean].include?(type)
          raise ValidationDefinitionError, "the type should be :numeric, :string or :boolean"
        end

        checks = {
          numeric: -> (value) {value.is_a?(Numeric)},
          string: -> (value) {value.is_a?(String)},
          boolean: -> (value) {!!value == value}
        }

        validate attribute_name, "should be #{type}", -> (value) {value.nil? || checks[type].call(value)}
      end
    end
  end
end
