module JetSet
  class EntityMapping
    attr_accessor :has_many, :belongs_to, :fields

    def initialize(&block)
      @has_many = []
      @belongs_to = []
      @fields = []

      instance_eval(&block)
    end

    def has_many(name)
      @has_many << name
    end

    def belongs_to(name)
      @belongs_to << name
    end

    def field(name)
      @fields << name
    end
  end
end