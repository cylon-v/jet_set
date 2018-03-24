module JetSet
  # Dependency graph stores a matrix of entities dependencies and is used by +JetSet::Session+
  # for ordering entities for persistence process using method +order+.
  class DependencyGraph
    # Initializes a dependency graph using a mapping definition.
    # Parameters:
    #   +mapping+:: JetSet::Mapping
    def initialize(mapping)
      @matrix = {}

      mapping.entity_mappings.keys.each do |key|
        entity = mapping.entity_mappings[key]
        @matrix[entity.type.name] = entity.dependencies.map{|d| d.name}
      end
    end

    # Orders entities according their dependencies in mapping definition.
    # Parameters:
    #   +entities+:: entities to order.
    def order(entities)
      groups = {}
      entities.each do |entity|
        groups[entity.class.name] ||= []
        groups[entity.class.name] << entity
      end

      type_order = groups.keys.sort{|a, b| @matrix[b].include?(a) ? -1 : 1}
      entity_order = type_order.map{|type| groups[type]}
      entity_order.flatten
    end
  end
end