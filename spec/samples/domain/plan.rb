class Plan
  extend JetSet::Validations

  attr_reader :name, :price
  validate :name, 'should not be nil', -> (value) {!value.nil?}
  validate :name, 'should not be empty', -> (value) {!value.empty?}

  def initialize(attrs = {})
    @name = attrs[:name]
    @price = attrs[:price]
    @created_at = DateTime.now
  end

  def update(attrs = {})
    @name = attrs[:name]
  end
end