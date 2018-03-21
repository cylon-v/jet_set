class Plan
  attr_reader :name, :price

  def initialize(attrs = {})
    @name = attrs[:name]
    @price = attrs[:price]
    @created_at = DateTime.now
  end

  def update(attrs = {})
    @name = attrs[:name]
  end
end