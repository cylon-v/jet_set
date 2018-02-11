require 'sequel'

module JetSet
  class Session
    def initialize(connection, mapper, query_parser)
      @connection = connection
      @mapper = mapper
      @objects = []
      @query_parser = query_parser
    end

    def [](name)
      @connection[name]
    end

    def execute(query, params, &block)
      sql = @query_parser.parse(query)
      @connection.fetch(sql, params).map{|row| instance_exec(row, &block)}
    end

    def map(type, row, prefix = '', &block)
      object = @mapper.map(type, row, self, prefix)
      instance_exec(object, &block)

      object
    end

    def preload(object, relation, query, params = {})
      sql = @query_parser.parse(query)
      rows = @connection.fetch(sql, params)
      @mapper.map_association(object, relation, rows, self)
    end

    def attach(object)
      @objects << object
    end

    def dirty_objects
      @objects.select{|object| object.dirty?}
    end

    def flush
      puts "Session flush. Dirty objects: #{dirty_objects.length}."
    end
  end
end