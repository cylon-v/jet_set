module JetSet
  class DependencyGraph
    def initialize(mapping)
      @matrix = {}

      mapping.entity_mappings.keys.each do |key|
        entity = mapping.entity_mappings[key]
        @matrix[entity.type.name] = entity.dependencies.map{|d| d.name}
      end
    end
  end
end