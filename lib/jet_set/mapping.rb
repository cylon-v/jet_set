require 'jet_set/entity_mapping'

module JetSet
  class Mapping
    def initialize(&block)
      @entity_mappings = {}
      instance_eval(&block)
    end

    def entity(name, &block)
      @entity_mappings[name] = EntityMapping.new(&block)
    end

    def get(name)
      @entity_mappings[name]
    end
  end
end