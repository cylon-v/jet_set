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

    def execute(sql, &mapping)
      @connection.fetch(sql).each{|row| mapping.call(row)}
    end

    def map(type, row, prefix = '')
      object = @mapper.map(type, row, prefix)
      @objects << object
      object
    end

    def dirty_objects
      @objects.select{|object| object.dirty?}
    end
  end
end