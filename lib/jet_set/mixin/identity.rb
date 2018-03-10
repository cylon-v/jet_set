module JetSet
  module Identity
    attr_reader :id

    def ==(object)
      self.class.name == object.class.name && @id == object.id
    end
  end
end