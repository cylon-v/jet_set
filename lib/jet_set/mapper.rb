require 'sequel'
require 'jet_set/mapper_error'

module JetSet
  # A converter of a data rows to object model according to a mapping.
  class Mapper
    # Parameters:
    #   +entity_builder+:: an instance of +JetSet::EntityBuilder+
    #   +mapping+:: an instance of +JetSet::Mapping+
    #   +container+:: IoC container (+Hypo::Container+) for resolving entity dependencies
    def initialize(entity_builder, mapping, container)
      @entity_builder = entity_builder
      @mapping = mapping
      @container = container

      @mapping.entity_mappings.values.each do |entity_mapping|
        container.register(entity_mapping.type)
      end
    end

    # Converts a table row to an object
    # Parameters:
    #   +type+:: entity type defined in the mapping
    #   +row+:: hash representation of table row
    #   +session+:: instance of +JetSet::Session+
    #   +prefix+:: (optional) custom prefix for extracting the type attributes,
    #     i.e."customer" for query:
    #       "SELECT u.name AS customer__name from users u"
    def map(type, row, session, prefix = '')
      entity_name = type.name.underscore.to_sym
      entity_mapping = @mapping.get(entity_name)

      object = @container.resolve(entity_name)

      keys = row.keys.map {|key| key.to_s}
      attributes = keys.select {|key| key.to_s.start_with? prefix + '__'}
                     .select {|key| entity_mapping.fields.include? key.sub(prefix + '__', '')}
                     .map {|key| {field: key.sub(prefix + '__', ''), value: row[key.to_sym]}}

      entity = @entity_builder.create(object)
      entity.load_attributes!(attributes)

      reference_names = keys.select {|key| !key.start_with?(prefix) && key.include?('__')}
                          .map {|key| key.split('__')[0]}
                          .uniq

      reference_names.each do |reference_name|
        if entity_mapping.references.key? reference_name.to_sym
          type = entity_mapping.references[reference_name.to_sym].type
          entity.set_reference! reference_name, map(type, row, session, reference_name)
        end
      end

      session.attach(entity)
      entity
    end

    # Constructs object model relationships between of complex objects.
    # Parameters:
    #   +target+:: an instance or an array of entity instances
    #   +name+:: name of the target attribute to bind
    #   +rows+:: an array of database rows (hashes)
    #   +session+:: an instance of +JetSet::Session+
    def map_association(target, name, rows, session)
      singular_name = name.to_s.singularize.to_sym
      entity_mapping = @mapping.get(singular_name)

      if target.is_a? Array
        relations = {}
        target_name = target[0].class.name.underscore
        back_relations = {}


        if rows.length > 0
          target_id_name = "#{target_name.underscore}_id"
          target_reference = entity_mapping.references[target_name.to_sym]

          rows.each do |row|
            relation = map(entity_mapping.type, row, session, singular_name.to_s)
            target_id = row[target_id_name.to_sym]

            if target_id.nil?
              raise MapperError, "Field \"#{target_id_name}\" is not defined in the query but it's required to construct \"#{name} to #{target_name}\" association. Just add it to SELECT clause."
            end

            relations[target_id] ||= []
            relations[target_id] << relation
            back_relations[relation.id] = target.select{|t| t.id == target_id}
          end

          target.each do |entry|
            target_id = entry.id
            relation_objects = relations[target_id]

            if relation_objects
              if target_reference
                relation_objects.each {|obj| obj.set_reference!(target_reference.name, entry)}
              end

              entry.set_collection!(name, relations[target_id])

              relation_objects.each{|obj| obj.set_collection!(target_name, back_relations[entry.id])}
            end
          end
        end

        {result: relations, ids: relations.keys}
      else
        target_name = target.class.name.underscore
        target_reference = entity_mapping.references[target_name.to_sym]
        result = rows.map do |row|
          relation = map(entity_mapping.type, row, session, singular_name.to_s)

          unless target_reference.nil?
            relation.set_reference!(target_reference.name, target)
          end

          relation
        end

        target.set_collection!(name, result)

        {result: result, ids: result.map {|i| i.id}}
      end

    end
  end
end
