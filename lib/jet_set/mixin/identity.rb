module JetSet
  module Identity
    def ==(object)
      self.class.name == object.class.name && @__id == object._id
    end

    def _id
      @__id
    end
  end
end