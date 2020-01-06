require 'jet_set/mixin/identity'
require 'jet_set/mixin/entity'
require 'jet_set/validations'

module JetSet
  # A converter of a pure Ruby object to JetSet trackable object.
  class EntityBuilder

    # Parameters:
    #   +mapping+:: an instance of +JetSet::Mapping+
    def initialize(mapping)
      @mapping = mapping
    end

    # Makes passed object to be trackable.
    # +object+:: pure Ruby object
    def create(object)
      object.instance_variable_set('@__attributes', {})
      object.instance_variable_set('@__references', {})
      object.instance_variable_set('@__collections', {})
      object.instance_variable_set('@__mapping', @mapping)
      object.instance_variable_set('@__factory', self)

      object.extend(Identity)
      object.extend(Entity)
      object.extend(Validations)
    end
  end
end