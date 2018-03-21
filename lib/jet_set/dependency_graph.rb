module JetSet
  class DependencyGraph
    def initialize(mapping)
      @matrix = {}

      mapping.entity_mappings.keys.each do |key|
        entity = mapping.entity_mappings[key]
        @matrix[entity.type.name] = entity.dependencies.map{|d| d.name}
      end
    end

    def order(entities)
      p @matrix

      groups = {}
      entities.each do |entity|
        groups[entity.class.name] ||= []
        groups[entity.class.name] << entity
      end

      type_order = groups.keys.sort{|a, b| @matrix[b].include?(a) ? -1 : 1}

      entity_order = type_order.map do |type|
        groups[type]
      end

      entity_order.flatten
    end
  end
end