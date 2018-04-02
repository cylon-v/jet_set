require 'spec_helper'
require 'sequel'
require 'logger'
require 'samples/mapping'
require 'samples/domain/plan'

RSpec.describe 'Many-to-many relationship', integration: true do
  Sequel.extension :migration

  before :all do
    @connection = Sequel.connect('sqlite:/')
    @connection.logger = Logger.new($stdout)
    Sequel::Migrator.run(@connection, 'spec/integration/migrations', :use_transactions => false)

    @container = Hypo::Container.new
    JetSet::init(Mapping.load_mapping, @container)
    @session = JetSet::open_session(@connection)
  end


  describe 'session attach and finalize' do
    it 'successfully saves many-to-many-relationships plain object' do
      group1 = Group.new
      group2 = Group.new
      customer1 = Customer.new
      customer2 = Customer.new

      customer1.groups << group1
      group2.customers << customer2

      @session.attach(group1, customer1, customer2, group2)
      @session.finalize

      customers_query = <<~SQL
        SELECT
          c.* AS ENTITY customer
        FROM customers c
      SQL

      groups_query = <<~SQL
        SELECT
          g.* AS ENTITY group,
          cg.customer_id
        FROM groups g
          INNER JOIN customer_groups cg ON cg.group_id = g.id
        WHERE cg.customer_id IN :customer_ids
      SQL

      customers = @session.fetch(Customer, customers_query) do |customers|
        preload(customers, :groups, groups_query, customer_ids: customers.map{|c| c.id})
      end

      expect(customers[0].groups.length).to eql(1)
      expect(customers[1].groups.length).to eql(1)
    end
  end
end