class Subscription
  attr_reader :plan, :extensions, :active, :started_at

  def initialize(attrs = {})
    @started_at = Date.today
    @active = false
    @plan = attrs[:plan]
    @customer = attrs[:customer]
    @extensions = []
  end

  def add_extension(extension)
    @extensions << extension
  end

  def activate
    @active = true
  end
end