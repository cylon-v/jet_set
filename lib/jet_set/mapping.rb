require 'jet_set/entity_mapping'
require 'sequel/extensions/inflector'

module JetSet
  class Mapping
    Sequel.extension :inflector

    def initialize(&block)
      @entity_mappings = {}
      instance_eval(&block)
    end

    def entity(type, &block)
      name = type.name.underscore.to_sym
      @entity_mappings[name] = EntityMapping.new(type, &block)
    end

    def get(name)
      @entity_mappings[name]
    end
  end
end