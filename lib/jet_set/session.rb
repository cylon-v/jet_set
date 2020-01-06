require 'sequel'

module JetSet
  class Session
    # Initializes +Session+ object.
    # Parameters:
    # +sequel+:: Sequel sequel object.
    # +mapper+:: Sequel rows to Ruby objects mapper.
    # +query_parser+:: a parser which evaluates JetSet extensions in SQL-expressions.
    def initialize(sequel, mapper, query_parser, entity_builder, dependency_graph)
      @sequel = sequel
      @mapper = mapper
      @objects = []
      @query_parser = query_parser
      @entity_builder = entity_builder
      @dependency_graph = dependency_graph
      @mutex = Mutex.new
    end

    # Fetches root entity using a result of +execute+ method.
    # Parameters:
    # +type+:: Ruby class of an object to map.
    # +expression+:: SQL-like query
    # +params+:: +query+ params
    # +&block+:: further handling of the result.
    def fetch(type, expression, params = {}, &block)
      unless type.is_a? Class
        raise MapperError, 'Parameter "type" should be a Class.'
      end

      query = @query_parser.parse(expression)
      unless query.refers_to?(type)
        raise MapperError, "The query doesn't contain \"AS ENTITY #{type.name.underscore}\" statement."
      end

      rows = @sequel.fetch(query.sql, params).to_a
      if rows.length == 0
        result = nil
      elsif rows.length == 1 && query.returns_single_item?
        result = @mapper.map(type, rows[0], self)
      else
        if query.returns_single_item?
          raise MapperError, "A single row was expected to map but the query returned #{rows.length} rows."
        end

        result = []
        rows.each do |row|
          result << @mapper.map(type, row, self)
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
      query = @query_parser.parse(query)
      rows = @sequel.fetch(query.sql, params).to_a
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
    # +objects+:: any Ruby objects defined in the mapping.
    def attach(*objects)
      to_attach = []
      objects.each do |object|
        if object.is_a? Array
          object.each{|o| to_attach << o}
        else
          to_attach << object
        end
      end

      @mutex.synchronize do
        to_attach.each do |object|
          obj = object.kind_of?(Entity) ? object : @entity_builder.create(object)
          @objects << obj
        end
      end
    end

    # Saves all changes of attached objects to the database.
    # * Compatible with +Hypo::Scope+ +finalize+ interface,
    # see Hypo docs at https://github.com/cylon-v/hypo.
    def finalize
      dirty_objects = @objects.select {|object| object.dirty?}
      ordered_objects = @dependency_graph.order(dirty_objects)

      begin
        if ordered_objects.length > 0
          @sequel.transaction do
            ordered_objects.each{|obj| obj.flush(@sequel)}
          end
        end
      ensure
        @mutex.synchronize do
          @objects = []
        end
      end
    end
  end
end