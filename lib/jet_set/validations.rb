require 'jet_set/validation_error'

module JetSet
  # Optional validation decorator. Adds validation logic to pure Ruby objects.
  module Validations
    @@validations = {}

    # The method checks for methods starting from "validate_" prefix
    # and performs validation for every dirty attribute which has corresponding validation method.
    # Example: for attribute "title" such method would have name "validate_title"
    def validate!(attributes = @@validations.keys)
      invalid_items = []
      attributes.each do |attribute|
        attribute_validations = @@validations[attribute] || []

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
    
    def validate(attribute_name, message, func)
      @@validations[attribute_name] ||= []
      @@validations[attribute_name] << {func: func, message: message}
    end
  end
end
