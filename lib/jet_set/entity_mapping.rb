require 'jet_set/reference'

module JetSet
  class EntityMapping
    attr_accessor :references, :collections, :fields

    def initialize(&block)
      @references = {}
      @collections = []
      @fields = []

      instance_eval(&block)
    end

    def field(name)
      @fields << name.to_s
    end

    def collection(name)
      @collections << name
    end

    def reference(name, attributes = {})
      @references[name] = Reference.new(name, attributes[:type])
    end
  end
end