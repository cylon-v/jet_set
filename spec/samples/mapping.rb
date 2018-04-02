require 'samples/domain/plan'
require 'samples/domain/customer'
require 'samples/domain/subscription'
require 'samples/domain/invoice'
require 'samples/domain/line_item'
require 'samples/domain/group'

class Mapping
  def self.load_mapping
    JetSet::map do
      entity Customer do
        field :first_name
        field :last_name
        collection :subscriptions, type: Subscription
        collection :invoices, type: Invoice
        collection :groups, type: Group, using: 'customer_groups'
        reference :plan, type: Plan, weak: true
      end

      entity Invoice do
        field :amount
        field :created_at
        collection :line_items, type: LineItem
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

      entity Group do
        field :name
        collection :customers, type: Customer, using: 'customer_groups'
      end
    end
  end
end