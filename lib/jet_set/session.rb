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

    def execute(sql, &block)
      @connection.fetch(sql).map{|row| instance_exec row, &block}
    end

    def map(type, row, prefix = '')
      object = @mapper.map(type, row, prefix)
      @objects << object
      object
    end

    def dirty_objects
      @objects.select{|object| object.dirty?}
    end

    def flush
      puts "Session flush. Dirty objects: #{dirty_objects.length}."
    end
  end
end