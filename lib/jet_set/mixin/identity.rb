module JetSet
  module Identity
    def ==(object)
      self.class.name == object.class.name && @id == object.id
    end

    def id
      @id
    end
  end
end