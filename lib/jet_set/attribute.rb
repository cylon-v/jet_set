module JetSet
  class Attribute
    attr_reader :name

    def initialize(name, value)
      @name = name
      @value = value
    end

    def changed?(value)
      if @value.kind_of?(Array) && value.kind_of?(Array)
        value1 = @value.map{|obj| obj.id}
        value2 = value.map{|obj| obj.id}
        value2 & value1 == value2
      else
        @value != value
      end
    end
  end
end