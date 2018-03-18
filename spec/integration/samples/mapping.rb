require 'integration/samples/domain/plan'
require 'integration/samples/domain/customer'
require 'integration/samples/domain/subscription'
require 'integration/samples/domain/invoice'
require 'integration/samples/domain/line_item'

class Mapping
  def self.load_mapping
    JetSet::Mapping.new do
      entity Customer do
        field :first_name
        field :last_name
        collection :subscriptions, type: Subscription
        collection :invoices, type: Invoice
        reference :plan, type: Plan, weak: true
      end

      entity Invoice do
        field :amount
        field :created_at
        collection :line_items
        reference :subscription, type: Subscription
      end

      entity LineItem do
        field :price
        field :quantity
        reference :invoice, type: Invoice
      end

      entity Plan do
        field :name
        field :price
      end

      entity Subscription do
        field :started_at
        field :active
        reference :customer, type: Customer
        reference :plan, type: Plan
      end
    end
  end
end