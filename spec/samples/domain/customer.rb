class Customer
  attr_reader :invoices, :subscriptions, :groups

  def initialize(attrs = {})
    @first_name = attrs[:first_name]
    @last_name = attrs[:last_name]
    @invoices = []
    @subscriptions = []
    @groups = []
  end

  def add_invoice(invoice)
    @invoices << invoice
  end
end