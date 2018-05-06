class Invoice
  attr_reader :created_at, :subscription, :line_items, :amount

  def initialize(attrs = {})
    @created_at = DateTime.now
    @subscription = attrs[:subscription]
    @line_items = []
    @amount = attrs[:amount] || 0
    @history = attrs[:history]
  end
end