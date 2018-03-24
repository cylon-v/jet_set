require 'jet_set/entity_mapping'

module JetSet
  # Represents JetSet Mapping.
  # Usage:
  #   JetSet::Mapping.new do
  #     entity Invoice do
  #       field :amount
  #       field :created_at
  #       collection :line_items
  #       reference :subscription, type: Subscription
  #     end
  #     ...
  #     entity User do
  #       field :amount
  #       field :created_at
  #       collection :line_items
  #       reference :subscription, type: Subscription
  #     end
  #   end
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
    # +type+:: an entity class
    # +&block+:: should contain mapping definitions of the entity attributes. See +JetSet::EntityMapping+ class.
    # Returns an instance of +EntityMapping+
    def entity(type, &block)
      name = type.name.underscore.to_sym
      @entity_mappings[name] = EntityMapping.new(type, &block)
    end

    # Returns an entity mapping by its +name+.
    # Parameters:
    # +name+:: string
    def get(name)
      @entity_mappings[name]
    end
  end
end