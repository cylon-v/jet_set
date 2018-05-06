module JetSet
  # Reference represents a mapping of complex type attribute (another entity).
  # Should be instantiated by method +reference+ of +JetSet::EntityMapping+ instance.
  class Reference
    attr_reader :name, :type

    # Parameters:
    #   +name+:: name of the attribute
    #   +type+:: class of an entity
    #   +weak+:: is it weak reference?
    def initialize(name, type, weak)
      @name = name
      @type = type
      @weak = weak
    end

    def weak?
      @weak
    end
  end
end