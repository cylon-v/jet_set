require 'jet_set/attribute'
require 'sequel'
require 'sequel/extensions/inflector'

module JetSet
  module Proxy
    Sequel.extension :inflector

    def load_attributes!(attributes)
      attributes.each do |attribute|
        name ="@#{attribute[:field]}"
        value = attribute[:value]
        instance_variable_set(name, value)
        @__attributes << Attribute.new(name, value)
      end
    end

    def set_reference!(name, value, reverse = false)
      @__references[name] = value

      #experimental
      @__reference_reverse ||= {}
      @__reference_reverse[name] = reverse

      instance_variable_set("@#{name}", value)
    end

    def set_collection!(name, value)
      @__collections[name] = value.map{|item| item.respond_to?(:id) ? item.id : nil}

      instance_variable_set("@#{name}", value)
    end

    def new?
      @id == nil
    end

    def dirty?
      attributes_changed = @__attributes.any? do |attribute|
        current_value = instance_variable_get(attribute.name)
        attribute.changed?(current_value)
      end

      collections_changed = @__collections.keys.any? do |name|
        initial_state = @__collections[name]
        current_state = instance_variable_get("@#{name}")
        to_delete = initial_state - current_state
        to_insert = current_state.select{|item| !item.respond_to?(:id)}
        to_insert.length > 0 || to_delete.length > 0
      end

      references_changed = @__references.keys.any? do |name|
        initial_state = @__references[name]
        current_state = instance_variable_get("@#{name}")
        current_state != initial_state
      end

      attributes_changed || references_changed || collections_changed
    end

    def dirty_attributes
      @__attributes.select do |attribute|
        current_value = instance_variable_get(attribute.name)
        attribute.changed?(current_value)
      end
    end

    def flush(connection)
      table_name = self.class.name.underscore.pluralize.to_sym
      table = connection[table_name]
      entity_name = self.class.name.underscore.to_sym
      entity = @__mapping.get(entity_name)
      if new?
        attributes = []
        entity.fields.each do |field|
          attributes << {field: field, value: instance_variable_get("@#{field}")}
        end

        load_attributes!(attributes)

        fields = @__attributes.map{|attribute| attribute.name.sub('@', '')}
                   .select{|a| a != 'id'}

        values = @__attributes.select{|attribute| attribute.name.sub('@', '') != 'id'}
                   .map{|a| a.value}

        entity.references.keys.each do |key|
          value = instance_variable_get("@#{key}")
          if value
            set_reference!(key, value)
            fields << "#{key}_id"
            values << value.instance_variable_get('@id')
          end
        end

        @id = table.insert(fields, values)
      elsif dirty?
        attributes = {}
        dirty_attributes.each{|attribute| attributes[attribute.name.sub('@', '')] = attribute.value}
        if attributes.keys.length > 0
          table.where(id: @id).update(attributes)
        end
      end

      # synchronize collections
      entity.collections.keys.each do |key|
        unless @__collections.key? key
          set_collection!(key, instance_variable_get("@#{key}"))
        end
      end

      @__collections.keys.each do |name|
        initial_state = @__collections[name]
        current_state = instance_variable_get("@#{name}")

        to_delete = initial_state.select{|item| !item.nil?} - current_state.select{|item| item.respond_to?(:id)}.map{|item| item.id}
        to_insert = current_state.select{|item| !item.respond_to?(:id)}

        if to_delete.length > 0
          ids = to_delete.join(', ')
          connection[name].where(id: ids).delete
        end

        if to_insert.length > 0
          to_insert.each do |item|
            @__factory.create(item, @__mapping)
            item.flush(connection)
          end
        end
      end
    end
  end
end