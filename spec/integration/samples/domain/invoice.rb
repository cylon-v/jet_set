class Invoice
  def initialize(attrs = {})
    @created_at = DateTime.now
    @subscription = attrs[:subscription]
    @line_items = []
    @amount = attrs[:amount] || 0
  end
end