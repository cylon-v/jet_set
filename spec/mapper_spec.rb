require 'spec_helper'
require 'jet_set/mapper'
require 'samples/domain/customer'
require 'samples/domain/group'
require 'samples/domain/plan'
require 'samples/domain/subscription'

RSpec.describe 'Mapper' do
  before :each do
    @entity_builder = double(:entity_builder)
    @mapping = double(:mapping)

    @session = double(:session)

    subscription_mapping = JetSet::EntityMapping.new(Subscription) do
      field :started_at
      field :active
      reference :customer, type: Customer
      reference :plan, type: Plan
    end

    plan_mapping = JetSet::EntityMapping.new(Plan) do
      field :name
    end

    customer_mapping = JetSet::EntityMapping.new(Customer) do
      field :first_name
      reference :group, type: Group
    end

    group_mapping = JetSet::EntityMapping.new(Group) do
      field :name
    end

    allow(@mapping).to receive(:entity_mappings).and_return({
      subscription: subscription_mapping,
      plan: plan_mapping,
      customer: customer_mapping,
      group: group_mapping
    })

    expect(@mapping).to receive(:get).with(:subscription).and_return(subscription_mapping)
    expect(@mapping).to receive(:get).with(:plan).and_return(plan_mapping)
    expect(@mapping).to receive(:get).with(:customer).and_return(customer_mapping)
    expect(@mapping).to receive(:get).with(:group).and_return(customer_mapping)

    @container = double(:container)
    allow(@container).to receive(:register)

    @subscription = Subscription.new
    @plan = Plan.new
    @customer = Customer.new
    @group = Group.new
  end

  describe 'map' do
    it 'converts a table row to a type from the mapping' do
      row_hash = {
        subscription__id: 1,
        subscription__active: false,
        plan__id: 2,
        plan__price: 100.0,
        customer__id: 3,
        customer__first_name: 'Alex',
        group__id: 4,
        group_name: 'Users'
      }

      expect(@container).to receive(:resolve).with(:subscription).and_return(@subscription)
      expect(@container).to receive(:resolve).with(:plan).and_return(@plan)
      expect(@container).to receive(:resolve).with(:customer).and_return(@customer)
      expect(@container).to receive(:resolve).with(:group).and_return(@group)

      @subscription_entity = double(:subscription_entity)
      @plan_entity = double(:plan_entity)
      @customer_entity = double(:customer_entity)
      @group_entity = double(:group_entity)

      expect(@entity_builder).to receive(:create).with(@subscription).and_return(@subscription_entity)
      expect(@subscription_entity).to receive(:load_attributes!)
      expect(@subscription_entity).to receive(:set_reference!).with('plan', @plan_entity)
      expect(@subscription_entity).to receive(:set_reference!).with('customer', @customer_entity)
      expect(@session).to receive(:attach).with(@subscription_entity)

      expect(@entity_builder).to receive(:create).with(@plan).and_return(@plan_entity)
      expect(@plan_entity).to receive(:load_attributes!)
      expect(@session).to receive(:attach).with(@plan_entity)

      expect(@entity_builder).to receive(:create).with(@group).and_return(@group_entity)
      expect(@group_entity).to receive(:load_attributes!)
      expect(@session).to receive(:attach).with(@group_entity)

      expect(@entity_builder).to receive(:create).with(@customer).and_return(@customer_entity)
      expect(@customer_entity).to receive(:load_attributes!)
      expect(@customer_entity).to receive(:set_reference!).with('group', @group_entity)
      expect(@session).to receive(:attach).with(@customer_entity)

      @mapper = JetSet::Mapper.new(@entity_builder, @mapping, @container)
      @mapper.map(Subscription, row_hash, @session)
    end
  end
end
