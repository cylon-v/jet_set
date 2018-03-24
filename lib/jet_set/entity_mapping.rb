require 'jet_set/reference'
require 'jet_set/collection'

module JetSet
  # Entity mapping is an element of JetSet mapping definition, see +JetSet::Mapping+.
  # Should be instantiated by method +entity+ of +JetSet::Mapping+ instance.
  class EntityMapping
    attr_reader :references, :collections, :fields, :type, :dependencies

    # Initializes the mapping using Ruby block.
    # Parameters:
    #   +type+:: an entity class
    #   +&block+:: should contain attributes definitions see methods +field+, +collection+, +reference+.
    def initialize(type, &block)
      @type = type
      @references = {}
      @collections = {}
      @dependencies = []
      @fields = ['id']

      instance_eval(&block)
    end

    # Defines an attribute of a simple type (String, Integer, etc)
    # Parameters:
    #   +name+:: attribute name
    def field(name)
      @fields << name.to_s
    end

    # Defines an attribute of a complex type - another entity defined in the mapping.
    # Parameters:
    #   +name+:: attribute name
    #   +params+::
    #     +type+:: class of the entity
    #     +weak+:: (optional) a flag for making a reference to an entity which is not directly
    #              associated for skipping persistence steps for it
    def reference(name, params = {})
      @references[name] = Reference.new(name, params[:type])
      @dependencies << params[:type] unless params[:weak]
    end

    # Defines an attribute-collection of a complex type - another entity defined in the mapping.
    # Parameters:
    #   +name+:: attribute name
    #   +params+::
    #     +type+:: class of the entity
    #     +using+:: (optional) a name of many-to-many association table if needed.
    def collection(name, params = {})
      @collections[name] = Collection.new(name, params[:type], params[:using])
    end
  end
end