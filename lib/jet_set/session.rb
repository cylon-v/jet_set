require 'sequel'

module JetSet
  class Session
    # Initializes +Session+ object.
    # Parameters:
    # +connection+:: Sequel connection object.
    # +mapper+:: Sequel rows to Ruby objects mapper.
    # +query_parser+:: a parser which evaluates JetSet extensions in SQL-expressions.
    def initialize(connection, mapper, query_parser, entity_builder, dependency_graph)
      @connection = connection
      @mapper = mapper
      @objects = []
      @query_parser = query_parser
      @entity_builder = entity_builder
      @dependency_graph = dependency_graph
    end

    # Executes SQL-like query for further mapping.
    # Parameters:
    # +query+:: SQL-like query
    # +params+:: +query+ params
    # +&block+:: +Proc+ object that maps returning result using +map+ and +preload+ methods.
    def execute(query, params = {}, &block)
      sql = @query_parser.parse(query)
      rows = @connection.fetch(sql, params).to_a

      if block_given?
        instance_exec(rows, &block)
      end
    end

    # Maps root entity using a result of +execute+ method.
    # Parameters:
    # +type+:: Ruby class of an object to map.
    # +rows+:: an array of rows returned by +execute+ method.
    # +prefix+:: (optional) a prefix for extracting the object
    #            fields like "guest" for parsing "SELECT u.id AS guest__id ...".
    # +&block+:: further handling of the result.
    def map(type, rows, prefix = type.name.underscore, &block)
      if rows.length == 0
        result = nil
      elsif rows.length == 1
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

    # Loads nested references and collections using sub-query
    # for previously loaded aggregation root, see +map+ method.
    # Parameters:
    # +target+:: single or multiple entities that are a Ruby objects constructed by +map+ or +preload+ method.
    # +relation+:: an object reference or collection name defined in JetSet mapping for the +target+.
    def preload(target, relation, query, params = {}, &block)
      sql = @query_parser.parse(query)
      rows = @connection.fetch(sql, params).to_a
      result = @mapper.map_association(target, relation, rows, self)

      if block_given?
        instance_exec(result[:result], result[:ids], &block)
      end
    end

    # Makes an object to be tracked by the session.
    # Since this moment all related to object changes will be saved on session finalization.
    # Use this method for newly created aggregation roots. No need to use it for new objects
    # that were bound to a root which is already attached. All objects loaded from the database
    # are already under the session tracking.
    # Parameters:
    # +object+:: any Ruby object defined in the mapping.
    def attach(*objects)
      to_attach = []
      objects.each do |object|
        if object.is_a? Array
          object.each{|o| to_attach << o}
        else
          to_attach << object
        end
      end

      to_attach.each do |object|
        obj = object.kind_of?(Entity) ? object : @entity_builder.create(object)
        @objects << obj
      end
    end

    # Saves all changes of attached objects to the database.
    def finalize
      dirty_objects = @objects.select {|object| object.dirty?}
      ordered_objects = @dependency_graph.order(dirty_objects)

      if ordered_objects.length > 0
        @connection.transaction do
          ordered_objects.each{|obj| obj.flush(@connection)}
        end
      end
    end
  end
end