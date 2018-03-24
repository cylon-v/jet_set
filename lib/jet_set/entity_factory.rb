require 'jet_set/mixin/identity'
require 'jet_set/mixin/entity'

module JetSet
  class EntityFactory
    def initialize(mapping)
      @mapping = mapping
    end

    def create(object)
      object.instance_variable_set('@__attributes', {})
      object.instance_variable_set('@__references', {})
      object.instance_variable_set('@__collections', {})
      object.instance_variable_set('@__mapping', @mapping)
      object.instance_variable_set('@__factory', self)

      object.extend(Identity)
      object.extend(Entity)
    end
  end
end