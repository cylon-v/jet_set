module JetSet
  module Identity
    def ==(object)
      self.class.name == object.class.name && @_id == object._id
    end
  end
end