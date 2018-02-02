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

    def set_mapping!(mapping)
      @mapping = mapping
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

    def assign(association_name, association)
      name = "@#{association_name.to_s}"
      instance_variable_set(name, association)

      self
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