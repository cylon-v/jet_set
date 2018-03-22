class Group
  attr_reader :name, :customers

  def initialize(attrs = {})
    @name = attrs[:name]
    @customers = []
  end
end