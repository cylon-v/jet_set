require 'spec_helper'
require 'sequel'
require 'logger'
require 'samples/mapping'
require 'samples/domain/customer'
require 'samples/domain/plan'
require 'samples/domain/subscription'
require 'samples/domain/invoice'

RSpec.describe 'Nested entity', integration: true do
  Sequel.extension :migration

  before :all do
    @connection = Sequel.connect('sqlite:/')
    @connection.logger = Logger.new($stdout)
    Sequel::Migrator.run(@connection, 'spec/samples/migrations', :use_transactions => false)

    @container = Hypo::Container.new
    JetSet::init(Mapping.load_mapping, @container)
    @session = JetSet::open_session(@connection)
  end


  describe 'session attach and finalize' do
    it 'successfully saves nested object' do
      plan = Plan.new(name: 'business', price: 25.0)
      new_customer = Customer.new(first_name: 'Ivan', last_name: 'Ivanov')
      subscription = Subscription.new(plan: plan, customer: new_customer, started_at: DateTime.now)
      invoice = Invoice.new(created_at: DateTime.now, subscription: subscription, amount: plan.price)
      new_customer.add_invoice(invoice)
      subscription.activate

      @session.attach(subscription, invoice, plan, new_customer)
      @session.finalize

      customer_query = <<~SQL
        SELECT
          c.* AS ENTITY customer
        FROM customers c
        LIMIT 1
      SQL

      invoices_sql = <<~SQL
        SELECT
          i.* AS ENTITY invoice
        FROM invoices i
          INNER JOIN subscriptions s ON i.subscription_id = s.id AND s.customer_id = :customer_id
      SQL

      line_items_sql = <<~SQL
        SELECT
          li.* AS ENTITY line_item,
          li.invoice_id
        FROM line_items li

        WHERE li.invoice_id IN :invoice_ids
      SQL

      subscriptions_sql = <<~SQL
        SELECT
          s.* AS ENTITY subscription,
          p.* AS ENTITY plan
        FROM subscriptions s
          INNER JOIN plans p ON s.plan_id = p.id
        WHERE s.customer_id = :customer_id
      SQL

      customer = @session.fetch(Customer, customer_query) do |customer|
        preload(customer, :invoices, invoices_sql, customer_id: customer.id) do |invoices, ids|
          preload(invoices, :line_items, line_items_sql, invoice_ids: ids)
        end

        preload(customer, :subscriptions, subscriptions_sql, customer_id: customer.id)
      end

      expect(customer.subscriptions[0].plan.name).to eql('business')
      expect(customer.invoices[0].amount).to eq(plan.price)
    end
  end
end