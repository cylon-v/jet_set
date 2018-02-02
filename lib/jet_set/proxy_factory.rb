require 'jet_set/mixin/identity'
require 'jet_set/mixin/proxy'

module JetSet
  class ProxyFactory
    def create(object, entity)
      object.extend(Identity)
      object.extend(Proxy)

      object.set_mapping!(entity)
    end
  end
end