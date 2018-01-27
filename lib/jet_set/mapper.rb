module JetSet
  class Mapper
    def initialize(proxy_factory)
      @proxy_factory = proxy_factory
    end

    def map(type, row, prefix = '')
      object = type.new({})
      attributes = row.keys
                     .select{|key| key.to_s.start_with? prefix}
                     .map{|key| {field: key.to_s.sub(prefix, ''), value: row[key]}}
      proxy = @proxy_factory.create(object)
      proxy.load_attributes!(attributes)

      proxy
    end
  end
end
