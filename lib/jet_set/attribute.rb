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
      if @value.kind_of?(Array) && value.kind_of?(Array)
        value1 = @value.map{|obj| obj.id}
        value2 = value.map{|obj| obj.id}
        value2 & value1 == value2
      else
        @value != value
      end
    end
  end
end