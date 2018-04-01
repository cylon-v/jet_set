module JetSet
  # A structure for tracking an entity attribute state.
  class Attribute
    attr_reader :name, :value

    # Initializes the attribute state
    def initialize(name, value)
      @name = name
      @value = value
    end

    # Returns +true+ if the attribute is changed and +false+ if it's not.
    # Parameters:
    #   +value+:: current value to compare.
    def changed?(value)
      @value != value
    end
  end
end