module JetSet
  module Identity
    def ==(object)
      self.class.name == object.class.name && @__id == object.__id
    end

    def __id
      @__id
    end
  end
end