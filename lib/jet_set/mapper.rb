require 'sequel'
require 'sequel/extensions/inflector'
require 'jet_set/mapper_error'

module JetSet
  class Mapper
    Sequel.extension :inflector

    def initialize(proxy_factory, mapping, container)
      @proxy_factory = proxy_factory
      @mapping = mapping
      @container = container

      @mapping.entity_mappings.values.each do |entity_mapping|
        container.register(entity_mapping.type)
      end
    end

    def map(type, row, session, prefix = '')
      entity_name = type.name.underscore.to_sym
      entity = @mapping.get(entity_name)

      object = @container.resolve(entity_name)

      keys = row.keys.map{|key| key.to_s}
      attributes =  keys.select {|key| key.to_s.start_with? prefix + '__'}
                     .select {|key| entity.fields.include? key.sub(prefix + '__', '')}
                     .map {|key| {field: key.sub(prefix + '__', ''), value: row[key.to_sym]}}

      proxy = @proxy_factory.create(object, @mapping)
      proxy.load_attributes!(attributes)

      reference_names = keys.select {|key| !key.start_with?(prefix) && key.include?('__')}
                     .map {|key| key.split('__')[0]}
                     .uniq

      reference_names.each do |reference_name|
        if entity.references.key? reference_name.to_sym
          type = entity.references[reference_name.to_sym].type
          proxy.set_reference! reference_name, map(type, row, session, reference_name)
        end
      end

      session.attach(proxy)
      proxy
    end

    def map_association(target, name, rows, session)
      singular_name = name.to_s.singularize.to_sym
      entity = @mapping.get(singular_name)

      if target.is_a? Array
        target_name = target[0].class.name.underscore
        target_reference = entity.references[target_name.to_sym]

        object_id_name = "#{target_name.underscore}_id"
        relations = {}
        rows.each do |row|
          relation = map(entity.type, row, session, singular_name.to_s)
          relation.set_reference!(target_reference.name, target[0])
          object_id = row[object_id_name.to_sym]

          if object_id.nil?
            raise MapperError, "Field \"#{object_id_name}\" is not defined in the query but it's required to construct \"#{name} to #{target_name}\" association. Just add it to SELECT clause."
          end

          relations[object_id] ||= []
          relations[object_id] << relation
        end

        target.each do |object|
          object_id = object.id
          object.set_collection!(name, relations[object_id])
        end

        {result: relations, ids: relations.keys}
      else
        target_name = target.class.name.underscore
        target_reference = entity.references[target_name.to_sym]
        result = rows.map do |row|
          relation = map(entity.type, row, session, singular_name.to_s)
          relation.set_reference!(target_reference.name, target, true)
          relation
        end

        target.set_collection!(name, result)

        {result: result, ids: result.map{|i| i.id}}
      end

    end
  end
end
