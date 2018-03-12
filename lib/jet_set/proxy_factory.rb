require 'jet_set/mixin/identity'
require 'jet_set/mixin/proxy'

module JetSet
  class ProxyFactory
    def create(object, mapping)
      object.instance_variable_set('@__attributes', [])
      object.instance_variable_set('@__references', {})
      object.instance_variable_set('@__collections', {})
      object.instance_variable_set('@__mapping', mapping)
      object.instance_variable_set('@__factory', self)

      object.extend(Identity)
      object.extend(Proxy)
    end
  end
end