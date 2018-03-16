class Customer
  attr_reader :invoices, :subscriptions

  def initialize(attrs = {})
    @first_name = attrs[:first_name]
    @last_name = attrs[:last_name]
    @invoices = []
    @subscriptions = []
  end
end