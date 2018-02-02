require 'sequel'
require 'sequel/extensions/inflector'

module JetSet
  class Mapper
    Sequel.extension :inflector

    def initialize(proxy_factory, mapping)
      @proxy_factory = proxy_factory
      @mapping = mapping
    end

    def map(type, row, prefix = '')
      entity_name = type.name.underscore.to_sym
      entity = @mapping.get(entity_name)

      object = type.new({})
      attributes = row.keys
                     .select{|key| key.to_s.start_with? prefix}
                     .select{|key| entity.fields.include? key.to_s.sub(prefix, '').to_sym}
                     .map{|key| {field: key.to_s.sub(prefix, '').to_sym, value: row[key]}}
      proxy = @proxy_factory.create(object)
      proxy.load_attributes!(attributes)

      proxy
    end
  end
end
