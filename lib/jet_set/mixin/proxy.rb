require 'jet_set/attribute'
require 'sequel'
require 'sequel/extensions/inflector'

module JetSet
  module Proxy
    Sequel.extension :inflector

    def load_attributes!(attributes)
      @__attributes = []

      attributes.each do |attribute|
        name ="@#{attribute[:field]}"
        value = attribute[:value]
        name = '@__id' if name == '@id'
        instance_variable_set(name, value)
        @__attributes << Attribute.new(name, value)
      end
    end

    def set_reference!(name, value, reverse = false)
      @__references ||= {}
      @__references[name] = value

      #experimental
      @__reference_reverse ||= {}
      @__reference_reverse[name] = reverse

      instance_variable_set("@#{name}", value)
    end

    def set_collection!(name, value)
      @__collections ||= {}
      @__collections[name] = value

      instance_variable_set("@#{name}", value)
    end

    def new?
      @__id == nil
    end

    def dirty?
      @__attributes.any? do |attribute|
        current_value = instance_variable_get(attribute.name)
        attribute.changed?(current_value)
      end
    end

    def dirty_attributes
      @__attributes.select do |attribute|
        current_value = instance_variable_get(attribute.name)
        attribute.changed?(current_value)
      end
    end

    ###
    # Returns pure plain Ruby object without JetSet stuff.
    ###
    def pure(nested = true)
      object = dup
      object.remove_instance_variable(:@__attributes)

      if @__references
        @__references.keys.each do |key|
          clean = @__references[key].pure(!@__reference_reverse[key])
          object.instance_variable_set("@#{key}", clean)
        end
        object.remove_instance_variable(:@__references)
      end

      if @__collections && nested
        @__collections.each do |name|
          items = object.instance_variable_get("@#{name}")
          items.each_with_index do |item, index|
            items[index] = item.pure
          end
        end
        object.remove_instance_variable(:@__collections)
      end

      object
    end

    def flush(connection)
      table_name = self.class.name.underscore.pluralize

      if dirty?
        assignments = dirty_attributes.map{|attribute| "#{attribute.name.sub('@', '')} = '#{attribute.value}'"}.join("\n")

        sql = <<~SQL
            UPDATE #{table_name}
            SET #{assignments}
            WHERE id = #{@__id}
        SQL

        p connection.run(sql)
      end

      if new?
        fields = dirty_attributes.map{|attribute| attribute.name.sub('@', '')}.join(', ')
        values = dirty_attributes.map{|attribute| "'#{attribute.value}'"}.join(', ')

        sql = <<~SQL
            INSERT INTO #{table_name} (#{fields})
            VALUES (#{values})
        SQL
        p connection.run(sql)
      end

      @__collections.keys.each do |name|
        initial_state = @__collections[name]
        current_state = instance_variable_get("@#{name}")

        to_delete = initial_state - current_state
        to_insert = current_state.select{|item| item.__id.nil?}

        if to_delete.length > 0
          ids = to_delete.map{|item| item.__id}.join(', ')
          sql = <<~SQL
            DELETE FROM #{table_name}
            WHERE id IN (#{ids})
          SQL

          connection.run(sql)
        end

        if to_insert.length > 0
          to_insert.each{|item| item.flush}
        end
      end
    end
  end
end