require 'sequel'

module JetSet
  class Session
    def initialize(connection, mapper)
      @connection = connection
      @mapper = mapper
      @objects = []
    end

    def [](name)
      @connection[name]
    end

    def execute(sql, params, &block)
      @connection.fetch(sql, params).map{|row| instance_exec row, &block}
    end

    def map(type, row, prefix = '')
      @mapper.map(type, row, self, prefix)
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