require 'jet_set/query'

module JetSet
  # A converter of JetSet syntax to SQL queries.
  class QueryParser
    # Initializes the parser
    # Parameters:
    #   +mapping+:: JetSet mapping +JetSet:Mapping+.
    def initialize(mapping)
      @mapping = mapping
    end

    # Parses JetSet query and returns SQL query.
    # Parameters:
    #   +expression+:: an SQL query with trivial extensions
    def parse(expression)
      sql = expression.dup

      returns_single_item = sql.scan(/LIMIT 1(\\n|;|\s)*\z/i).any?
      entity_matches = sql.scan(/(\s*)(\w+)\.\*\s+AS\s+ENTITY\s+(\w+)/i)
      entity_expressions = sql.scan(/(\w+\.\*\s+AS\s+ENTITY\s+\w+)/i).flatten

      entities = []
      entity_matches.each_with_index do |match, index|
        spaces_str = match[0]
        alias_name = match[1]
        entity_name = match[2]
        entity = @mapping.get(entity_name.to_sym)
        entities << entity
        fields_sql = entity.fields.map {|field| "#{alias_name}.#{field} AS #{entity_name}__#{field}"}.join(",#{spaces_str}")
        sql.sub!(entity_expressions[index], fields_sql)
      end

      Query.new({
        sql: sql,
        returns_single_item: returns_single_item,
        entities: entities
      })
    end
  end
end