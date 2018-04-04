module JetSet
  # Parsed JetSet query
  class Query
    attr_reader :sql

    # Parameters:
    #   attrs:
    #     sql: parsed valid SQL expression
    #     returns_single_item: does SQL expression return single row? (LIMIT 1)
    #     entities: entities (+JetSet:EntityMapping+) enumerated in the query statements
    def initialize(attrs = {})
      @sql = attrs[:sql]
      @returns_single_item = attrs[:returns_single_item] || false
      @entities = attrs[:entities] || []
    end

    # Does SQL expression return single row? (LIMIT 1)
    def returns_single_item?
      @returns_single_item
    end

    # Is entity type enumerated in ENTITY statements?
    def refers_to?(type)
      @entities.any?{|entity| entity.type == type}
    end
  end
end