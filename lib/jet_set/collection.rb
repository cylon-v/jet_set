module JetSet
  class Collection
    attr_reader :name, :type, :using

    def initialize(name, type, using = nil)
      @name = name
      @type = type
      @using = using
    end
  end
end