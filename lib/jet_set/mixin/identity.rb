module JetSet
  # Identity decorator. Adds identifier to pure Ruby objects.
  module Identity
    # Compares the object with another object using their types and IDs.
    def ==(object)
      self.class == object.class && @id == object.id
    end

    # Object identifier
    def id
      @id
    end
  end
end