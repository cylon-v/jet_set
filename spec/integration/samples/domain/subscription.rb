class Subscription
  attr_reader :plan, :extensions, :active

  def initialize(attrs = {})
    @started_at = Date.today
    @active = false
    @plan = attrs[:plan]
    @user = attrs[:user]
    @extensions = []
  end


  def add_extension(extension)
    @extensions << extension
  end
end