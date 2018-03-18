require 'jet_set/reference'
require 'jet_set/collection'

module JetSet
  class EntityMapping
    attr_reader :references, :collections, :fields, :type, :dependencies

    def initialize(type, &block)
      @type = type
      @references = {}
      @collections = {}
      @dependencies = []
      @fields = ['id']

      instance_eval(&block)
    end

    def field(name)
      @fields << name.to_s
    end

    def collection(name, attributes = {})
      @collections[name] = Collection.new(name, attributes[:type])
    end

    def reference(name, attributes = {})
      @references[name] = Reference.new(name, attributes[:type])
      @dependencies << attributes[:type] unless attributes[:weak]
    end
  end
end