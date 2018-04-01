module JetSet
  # Collection represents a collection attribute mapping.
  # Should be instantiated by method +collection+ of +JetSet::EntityMapping+ instance.
  class Collection
    attr_reader :name, :type, :using_table

    # Parameters:
    #   +name+:: name of the attribute
    #   +type+:: class of an entity
    #   +using_table+:: (optional) name of many-to-many association table if needed.
    def initialize(name, type, using_table = nil)
      @name = name
      @type = type
      @using_table = using_table
    end
  end
end