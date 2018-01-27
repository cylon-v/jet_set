require 'jet_set/mixin/identity'
require 'jet_set/mixin/proxy'

module JetSet
  class ProxyFactory
    def create(object)
      object.extend(Identity)
      object.extend(Proxy)

      object
    end
  end
end