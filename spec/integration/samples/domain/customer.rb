class Customer
  attr_reader :invoices, :subscriptions

  def initialize(attrs = {})
    @first_name = attrs[:first_name]
    @last_name = attrs[:last_name]
    @invoices = []
    @subscriptions = []
  end

  def add_invoice(invoice)
    @invoices << invoice
  end
end