module JetSet
  # Reference represents a mapping of complex type attribute (another entity).
  # Should be instantiated by method +reference+ of +JetSet::EntityMapping+ instance.
  class Reference
    attr_reader :name, :type

    # Parameters:
    #   +name+:: name of the attribute
    #   +type+:: class of an entity
    def initialize(name, type)
      @name = name
      @type = type
    end
  end
end