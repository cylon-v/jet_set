require 'sequel'

module JetSet
  class Session
    # Initializes +Session+ object.
    # Params:
    # +connection+:: Sequel connection object.
    # +mapper+:: Sequel rows to Ruby objects mapper.
    # +query_parser+:: a parser which evaluates JetSet extensions in SQL-expressions.
    def initialize(connection_string, mapper, query_parser, proxy_factory)
      connection = Sequel.connect(connection_string)
      connection.logger = Logger.new($stdout)

      @connection = connection
      @mapper = mapper
      @objects = []
      @query_parser = query_parser
      @proxy_factory = proxy_factory
    end

    # Executes SQL-like query for further mapping.
    # Params:
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
    # Params:
    # +type+:: Ruby class of an object to map.
    # +rows+:: an array of rows returned by +execute+ method.
    # +prefix+:: (optional) a prefix for extracting the object
    #            fields like "guest" for parsing "SELECT u.id AS guest__id ...".
    # +&block+:: further handling of the result.
    def map(type, rows, prefix = type.name.underscore, &block)
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

    # Loads nested references and collections using sub-query
    # for previously loaded aggregation root, see +map+ method.
    # Params:
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
    # Params:
    # +object+:: any Ruby object defined in the mapping.
    def attach(object)
      @objects << object
    end

    # Saves all changes of attached objects to the database and close the connection.
    def finalize
      dirty_objects = @objects.select {|object| object.dirty?}

      if dirty_objects.length > 0
        @connection.transaction do
          dirty_objects.each{|obj| obj.flush(@connection)}
        end
      end

      @connection.disconnect
    end
  end
end