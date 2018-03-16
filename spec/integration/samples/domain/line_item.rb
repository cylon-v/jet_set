class LineItem
  def initialize(attrs = {})
    @price = attrs[:price]
    @quantity = attrs[:quantity]
  end
end