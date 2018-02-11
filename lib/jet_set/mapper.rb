require 'sequel'
require 'sequel/extensions/inflector'

module JetSet
  class Mapper
    Sequel.extension :inflector

    def initialize(proxy_factory, mapping)
      @proxy_factory = proxy_factory
      @mapping = mapping
    end

    def map(type, row, session, prefix = '')
      entity_name = type.name.underscore.to_sym
      entity = @mapping.get(entity_name)

      object = type.new({})

      keys = row.keys.map{|key| key.to_s}
      attributes =  keys.select {|key| key.to_s.start_with? prefix + '__'}
                     .select {|key| entity.fields.include? key.sub(prefix + '__', '')}
                     .map {|key| {field: key.sub(prefix + '__', ''), value: row[key.to_sym]}}

      proxy = @proxy_factory.create(object)
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

    def map_association(object, name, rows, session)
      singular_name = name.to_s.singularize.to_sym
      entity = @mapping.get(singular_name)
      result = rows.map{|row| map(entity.type, row, session, '__' + singular_name.to_s)}
      object.instance_variable_set("@#{name}", result)
    end
  end
end
