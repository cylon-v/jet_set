class Extension
  def initialize(attrs = {})
    @added_at = DateTime.now
    @type = self.class.name.underscore
  end

  def call
    @last_called_at = DateTime.now
  end
end