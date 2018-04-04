require 'jet_set/entity_mapping'

module JetSet
  # Represents JetSet Mapping.
  class Mapping
    attr_reader :entity_mappings

    # Initializes the mapping using Ruby block.
    # Parameters:
    #   +&block+:: should contain "entity" definitions see method +entity+.
    def initialize(&block)
      @entity_mappings = {}
      instance_eval(&block)
    end

    # Defines an entity mapping
    # Parameters:
    #   +type+:: an entity class
    #   +&block+:: should contain mapping definitions of the entity attributes. See +JetSet::EntityMapping+ class.
    # Returns an instance of +EntityMapping+
    def entity(type, &block)
      unless type.is_a? Class
        raise MapperError, 'Mapping definition of an entity should begin from a type declaration which should be a Class.'
      end

      name = type.name.underscore.to_sym
      if @entity_mappings.has_key?(name)
        raise MapperError, "Mapping definition for entity of type #{type} is already registered."
      end

      @entity_mappings[name] = EntityMapping.new(type, &block)
    end

    # Returns an entity mapping by its +name+.
    # Parameters:
    #   +name+:: string
    def get(name)
      @entity_mappings[name]
    end
  end
end