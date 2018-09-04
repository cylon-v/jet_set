class Group
  attr_reader :name, :customers

  def initialize(attrs = {})
    if attrs[:name].nil?
      raise 'Group should contain name'
    end

    @name = attrs[:name]
    @customers = []
  end
end