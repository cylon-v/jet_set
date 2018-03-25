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
    #   +query+:: an SQL query with trivial extensions
    def parse(query)
      entity_matches = query.scan(/(\s*)(\w+)\.\*\s+AS\s+ENTITY\s+(\w+)/)
      entity_expressions = query.scan(/(\w+\.\*\s+AS\s+ENTITY\s+\w+)/).flatten

      entity_matches.each_with_index do |match, index|
        spaces_str = match[0]
        alias_name = match[1]
        entity_name = match[2]
        entity = @mapping.get(entity_name.to_sym)
        sql = entity.fields.map{|field| "#{alias_name}.#{field} AS #{entity_name}__#{field}"}.join(",#{spaces_str}")
        query.sub!(entity_expressions[index], sql)
      end

      query
    end
  end
end