module JetSet
  class ValidationError < StandardError
    attr_reader :invalid_items

    def initialize(message, invalid_items = {})
      super(message)
      @invalid_items = invalid_items
    end
  end
end