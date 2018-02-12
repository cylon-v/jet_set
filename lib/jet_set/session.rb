require 'sequel'
require 'sequel/extensions/inflector'

module JetSet
  class Session
    Sequel.extension :inflector

    def initialize(connection, mapper, query_parser)
      @connection = connection
      @mapper = mapper
      @objects = []
      @query_parser = query_parser
    end

    def [](name)
      @connection[name]
    end

    def execute(query, params = {}, &block)
      sql = @query_parser.parse(query)
      rows = @connection.fetch(sql, params).to_a

      if block_given?
        instance_exec(rows, &block)
      end
    end

    def map(type, rows, prefix = '', &block)
      if rows.length == 1
        result = @mapper.map(type, rows[0], self, prefix)
      else
        result = []
        rows.each do |row|
          result << @mapper.map(type, row, self, prefix)
        end
      end

      if block_given?
        instance_exec(result, &block)
      end

      result
    end


    def preload(target, relation, query, params = {})
      sql = @query_parser.parse(query)
      rows = @connection.fetch(sql, params).to_a
      @mapper.map_association(target, relation, rows, self)
    end

    def attach(object)
      @objects << object
    end

    def dirty_objects
      @objects.select {|object| object.dirty?}
    end

    def flush
      puts "Session flush. Dirty objects: #{dirty_objects.length}."
    end
  end
end