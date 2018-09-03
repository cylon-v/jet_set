module JetSet
  # A container for fields/references extraction logic
  class Row
    attr_reader :attributes, :attributes_hash, :reference_names

    def initialize(row_hash, entity_fields, prefix)
      keys = row_hash.keys.map {|key| key.to_s}

      @attributes = keys.select {|key| key.to_s.start_with? prefix + '__'}
        .select {|key| entity_fields.include? key.sub(prefix + '__', '')}
        .map {|key| {field: key.sub(prefix + '__', ''), value: row_hash[key.to_sym]}}

      @attributes_hash = {}
      @attributes.each do |attr|
        @attributes_hash[attr[:field].to_sym] = attr[:value]
      end

      @reference_names = keys.select {|key| !key.start_with?(prefix) && key.include?('__')}
        .map {|key| key.split('__')[0]}
        .uniq
    end
  end
end