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
      @__collections ||= []
      @__collections << name

      instance_variable_set("@#{name}", value)
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

    def flush
      if dirty?
        if @id != nil
        else
        end
      end
    end
  end
end