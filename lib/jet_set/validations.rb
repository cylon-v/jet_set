require 'jet_set/validation_error'

module JetSet
  # Optional validation decorator. Adds validation logic to pure Ruby objects.
  module Validations
    # The method runs all validations declared in the model
    def validate!
      @to_skip ||= []

      validations = self.class.class_variable_defined?(:@@validations) ? self.class.class_variable_get(:@@validations) : {}
      attributes = validations.keys - @to_skip
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

    # Disables attribute validation for edge cases
    def do_not_validate(*attributes)
      @to_skip ||= []
      attributes.each { |a| @to_skip << a}
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Adds a validation to an attribute of the entity
      # Parameters:
      #   +attribute_name+:: +Symbol+ attribute name
      #   +options+ || +message+:: validation options {type, presence, message, custom} or just a message
      #   +func+:: boolean proc with a check for validity
      def validate(attribute_name, options, func = nil)
        validations = self.class_variable_defined?(:@@validations) ? self.class_variable_get(:@@validations) : {}
        validations[attribute_name] ||= []

        if options.is_a?(Hash)
          if options.has_key?(:type)
            validations[attribute_name] << validate_type(options[:type])
          end

          if options[:presence] == true
            validations[attribute_name] << validate_presence
          end

          message = options[:message]
        elsif options.is_a?(String)
          message = options
        else
          raise ValidationDefinitionError, "Validation definition of attribute #{attribute_name} is incorrect."
        end

        func ||= options[:custom]

        unless func.nil?
          validations[attribute_name] << {func: func, message: message}
        end

        self.class_variable_set(:@@validations, validations)
      end

      private

      def validate_presence
        {message: 'cannot be blank', func: -> (value) {!value.nil? && value != ''}}
      end

      def validate_type(type)
        unless [:numeric, :string, :boolean].include?(type)
          raise ValidationDefinitionError, "the type should be :numeric, :string or :boolean"
        end

        checks = {
          numeric: -> (value) {value.is_a?(Numeric)},
          string: -> (value) {value.is_a?(String)},
          boolean: -> (value) {!!value == value}
        }

        {message: "should be #{type}", func: -> (value) {value.nil? || checks[type].call(value)}}
      end
    end
  end
end
