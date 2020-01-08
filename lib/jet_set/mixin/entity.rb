require 'jet_set/attribute'

module JetSet
  # A decorator for domain objects.
  # It adds JetSet specific stuff for object changes tracking and persistence.
  module Entity
    # Loads the entity attributes.
    # Parameters:
    #   +attributes+:: an array of key-pairs in format :field => :value
    def load_attributes!(attributes)
      attributes.each do |attribute|
        name = "@#{attribute[:field]}"
        value = attribute[:value]
        instance_variable_set(name, value)
        @__attributes[name] = Attribute.new(name, value)
      end
    end

    # Sets a reference to another entity.
    # Parameters:
    #   +name+:: name of an entity defined in the mapping
    #   +value+:: an instance of an entity
    def set_reference!(name, value)
      @__references[name] = value
      instance_variable_set("@#{name}", value)
    end

    # Sets a collection of related entities.
    # Parameters:
    #   +name+:: name of an entity defined in the mapping
    #   +value+:: an array of instances of the entity
    def set_collection!(name, value)
      @__collections[name] = value.map{|item| item.respond_to?(:id) ? item.id : nil}.select{|item| !item.nil?}
      instance_variable_set("@#{name}", value)
    end

    # Returns +true+ if entity is not loaded from the database and +false+ if it is.
    def new?
      @id.nil?
    end

    # Returns +true+ if the entity contains unsaved changes (attributes, references, collection)
    # or if it's new (see +new?+ method).
    def dirty?
      attributes_changed = @__attributes.keys.any? do |name|
        attribute = @__attributes[name]
        current_value = instance_variable_get(attribute.name)
        attribute.changed?(current_value)
      end

      collections_changed = @__collections.keys.any? do |name|
        initial_state = @__collections[name]
        current_state = instance_variable_get("@#{name}").map{|item| item.id}.select{|id| !id.nil?}
        to_delete = initial_state - current_state
        to_insert = current_state.select {|item| !item.respond_to?(:id)}
        to_insert.length > 0 || to_delete.length > 0
      end

      references_changed = @__references.keys.any? do |name|
        initial_state = @__references[name]
        current_state = instance_variable_get("@#{name}")
        current_state != initial_state
      end

      attributes_changed || references_changed || collections_changed || new?
    end

    # Enumerates changed attributes
    def dirty_attributes
      @__attributes.keys.select {|name|
        current_value = instance_variable_get(name)
        @__attributes[name].changed?(current_value)
      }.map {|name| @__attributes[name]}
    end

    # Flushes current state and saves a changes to the database.
    # Parameters:
    #   +sequel+:: Sequel sequel
    def flush(sequel)
      validate!

      table_name = self.class.name.underscore.pluralize.to_sym
      table = sequel[table_name]
      entity_name = self.class.name.underscore.to_sym
      my_column_name = self.class.name.underscore + '_id'

      entity = @__mapping.get(entity_name)

      if new?
        attributes = []
        entity.fields.each do |field|
          attributes << {field: field, value: instance_variable_get("@#{field}")}
        end

        load_attributes!(attributes)

        fields = @__attributes.keys.map {|name| name.sub('@', '')}.select {|a| a != 'id'}
        values = @__attributes.keys.select {|name| name.sub('@', '') != 'id'}.map {|name| @__attributes[name].value}

        entity.references.keys.each do |key|
          value = instance_variable_get("@#{key}")
          reference = entity.references[key]

          if value
            reference_id = value.instance_variable_get('@id')

            if reference_id.nil? && !reference.weak?
              @__factory.create(value)
              value.flush(sequel)
            end

            set_reference!(key, value)
            fields << "#{key}_id"

            values << value.instance_variable_get('@id')
          end
        end

        new_id = table.insert(fields, values)
        @__attributes['@id'] = Attribute.new('@id', new_id)
        @id = new_id
      elsif dirty?
        attributes = {}
        dirty_attributes.each {|attribute| attributes[attribute.name.sub('@', '')] = instance_variable_get(attribute.name)}

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
          if entity.collections[name].using
            foreign_column_name = name.to_s.singularize.underscore + '_id'
            to_delete.each do |foreign_id|
              sequel[entity.collections[name].using.to_sym].where(my_column_name => id, foreign_column_name => foreign_id).delete
            end
          else
            sequel[name].where(id: to_delete).delete
          end
        end

        to_insert.each do |item|
          @__factory.create(item)
          item.flush(sequel)
        end

        if entity.collections[name].using
          to_association_insert = []
          current_state.each do |current_item|
            to_association_insert << current_item unless initial_state.any?{|item| item == current_item}
          end

          relation_table = entity.collections[name].using.to_sym

          to_association_insert.each do |item|
            unless item.id
              @__factory.create(item)
              item.flush(sequel)
            end

            foreign_column_name = item.class.name.underscore + '_id'
            sequel[relation_table].insert([my_column_name, foreign_column_name], [@id, item.id])
          end
        end
      end
    end
  end
end