require 'spec_helper'
require 'jet_set/mapper'
require 'jet_set/mapper_error'
require 'samples/domain/customer'
require 'samples/domain/group'
require 'samples/domain/plan'
require 'samples/domain/subscription'
require 'samples/domain/invoice'
require 'samples/domain/line_item'
require 'samples/mapping'

RSpec.describe 'Mapper' do
  before :each do
    @entity_builder = double(:entity_builder)

    @container = double(:container)
    allow(@container).to receive(:register)

    @session = double(:session)

    @mapper = JetSet::Mapper.new(@entity_builder, Mapping.load_mapping, @container)
  end

  describe 'map' do
    before :each do
      @subscription = Subscription.new
      @plan = Plan.new
      @customer = Customer.new
      @group = Group.new
    end

    it 'converts a table row to a type from the mapping' do
      row_hash = {
        subscription__id: 1,
        subscription__active: false,
        plan__id: 2,
        plan__price: 100.0,
        customer__id: 3,
        customer__first_name: 'Alex'
      }

      allow(@container).to receive(:resolve).with(:subscription).and_return(@subscription)
      allow(@container).to receive(:resolve).with(:plan).and_return(@plan)
      allow(@container).to receive(:resolve).with(:customer).and_return(@customer)

      @subscription_entity = double(:subscription_entity)
      @plan_entity = double(:plan_entity)
      @customer_entity = double(:customer_entity)

      expect(@entity_builder).to receive(:create).with(@subscription).and_return(@subscription_entity)
      expect(@subscription_entity).to receive(:load_attributes!)
      expect(@subscription_entity).to receive(:set_reference!).with('plan', @plan_entity)
      expect(@subscription_entity).to receive(:set_reference!).with('customer', @customer_entity)
      expect(@session).to receive(:attach).with(@subscription_entity)

      expect(@entity_builder).to receive(:create).with(@plan).and_return(@plan_entity).twice
      expect(@plan_entity).to receive(:load_attributes!).twice
      expect(@session).to receive(:attach).with(@plan_entity).twice

      expect(@entity_builder).to receive(:create).with(@customer).and_return(@customer_entity)
      expect(@customer_entity).to receive(:load_attributes!)
      expect(@customer_entity).to receive(:set_reference!).with('plan', @plan_entity)
      expect(@session).to receive(:attach).with(@customer_entity)

      @mapper.map(Subscription, row_hash, @session)
    end
  end

  describe 'map_association' do
    context 'when target is not an array' do
      it 'adds a complex association to the target' do
        @invoice_entity = double(:invoice_entity)
        @line_item1 = LineItem.new
        @line_item2 = LineItem.new

        @line_item_entity1 = double(:line_item_entity1)
        @line_item_entity2 = double(:line_item_entity2)

        allow(@line_item_entity1).to receive(:id).and_return(1)
        allow(@line_item_entity2).to receive(:id).and_return(2)

        @invoice = Invoice.new

        allow(@invoice_entity).to receive(:class).and_return(Invoice)

        expect(@container).to receive(:resolve).with(:line_item).and_return(@line_item1)
        expect(@container).to receive(:resolve).with(:line_item).and_return(@line_item2)

        expect(@container).to receive(:resolve).with(:invoice).and_return(@invoice).twice

        expect(@entity_builder).to receive(:create).with(@line_item1).and_return(@line_item_entity1)
        expect(@entity_builder).to receive(:create).with(@line_item2).and_return(@line_item_entity2)
        expect(@entity_builder).to receive(:create).with(@invoice).and_return(@invoice_entity).twice

        expect(@line_item_entity1).to receive(:load_attributes!)
        expect(@line_item_entity2).to receive(:load_attributes!)

        expect(@invoice_entity).to receive(:load_attributes!).twice
        expect(@session).to receive(:attach).with(@invoice_entity).twice

        expect(@session).to receive(:attach).with(@line_item_entity1)
        expect(@session).to receive(:attach).with(@line_item_entity2)

        expect(@invoice_entity).to receive(:set_collection!).with(:line_items, [@line_item_entity1, @line_item_entity2])
        expect(@line_item_entity1).to receive(:set_reference!).with('invoice', @invoice_entity)
        expect(@line_item_entity2).to receive(:set_reference!).with('invoice', @invoice_entity)


        row_hashes = [{
          line_item__id: 1,
          line_item__price: 100.0,
          line_item__quantity: 1,
          invoice__id: 30
        }, {
          line_item__id: 2,
          line_item__price: 50.0,
          line_item__quantity: 1,
          invoice__id: 30
        }]

        result = @mapper.map_association(@invoice_entity, :line_items, row_hashes, @session)
        expect(result).to eq({
          result: [@line_item_entity1, @line_item_entity2],
          ids: [1, 2]
        })
      end
    end

    context 'when target is an array' do
      before :each do
        @invoice_entity1 = double(:invoice_entity1)
        @invoice_entity2 = double(:invoice_entity2)

        @line_item1 = LineItem.new
        @line_item2 = LineItem.new

        @line_item_entity1 = double(:line_item_entity1)
        @line_item_entity2 = double(:line_item_entity2)

        allow(@line_item_entity1).to receive(:id).and_return(1)
        allow(@line_item_entity2).to receive(:id).and_return(2)

        @invoice1 = Invoice.new
        @invoice2 = Invoice.new

        allow(@invoice_entity1).to receive(:class).and_return(Invoice)
        allow(@invoice_entity2).to receive(:class).and_return(Invoice)

        allow(@container).to receive(:resolve).with(:invoice).and_return(@invoice1)
        allow(@container).to receive(:resolve).with(:invoice).and_return(@invoice2)
      end

      context 'when reverse id is not defined' do
        it 'raises MapperError with specific message' do
          expect(@container).to receive(:resolve).with(:line_item).and_return(@line_item1)

          allow(@entity_builder).to receive(:create).with(@line_item1).and_return(@line_item_entity1)
          allow(@entity_builder).to receive(:create).with(@line_item2).and_return(@line_item_entity2)

          allow(@entity_builder).to receive(:create).with(@invoice1).and_return(@invoice_entity1)
          allow(@entity_builder).to receive(:create).with(@invoice2).and_return(@invoice_entity2)

          allow(@line_item_entity1).to receive(:load_attributes!)
          allow(@line_item_entity2).to receive(:load_attributes!)

          allow(@line_item_entity1).to receive(:load_attributes!)
          allow(@line_item_entity2).to receive(:load_attributes!)

          allow(@invoice_entity1).to receive(:load_attributes!)
          allow(@invoice_entity2).to receive(:load_attributes!)

          allow(@session).to receive(:attach)

          row_hashes = [{
            line_item__id: 1,
            line_item__price: 100.0,
            line_item__quantity: 1
          }, {
            line_item__id: 2,
            line_item__price: 50.0,
            line_item__quantity: 1
          }]

          expect{
            @mapper.map_association([@invoice_entity1, @invoice_entity2], :line_items, row_hashes, @session)
          }.to raise_error(JetSet::MapperError, "Field \"invoice_id\" is not defined in the query but it's required to construct \"line_items to invoice\" association. Just add it to SELECT clause.")
        end
      end

      it 'adds a complex association to the array of targets' do
        expect(@container).to receive(:resolve).with(:line_item).and_return(@line_item1)
        expect(@container).to receive(:resolve).with(:line_item).and_return(@line_item2)

        expect(@entity_builder).to receive(:create).with(@line_item1).and_return(@line_item_entity1)
        expect(@entity_builder).to receive(:create).with(@line_item2).and_return(@line_item_entity2)

        allow(@line_item_entity1).to receive(:id).and_return(1)
        allow(@line_item_entity2).to receive(:id).and_return(2)

        expect(@line_item_entity1).to receive(:load_attributes!)
        expect(@line_item_entity2).to receive(:load_attributes!)

        allow(@invoice_entity1).to receive(:id).and_return(30)
        allow(@invoice_entity2).to receive(:id).and_return(31)

        expect(@session).to receive(:attach).with(@line_item_entity1)
        expect(@session).to receive(:attach).with(@line_item_entity2)

        expect(@invoice_entity1).to receive(:set_collection!).with(:line_items, [@line_item_entity1])
        expect(@invoice_entity2).to receive(:set_collection!).with(:line_items, [@line_item_entity2])
        expect(@line_item_entity1).to receive(:set_reference!).with(:invoice, @invoice_entity1)
        expect(@line_item_entity2).to receive(:set_reference!).with(:invoice, @invoice_entity2)

        row_hashes = [{
          line_item__id: 1,
          line_item__price: 100.0,
          line_item__quantity: 1,
          invoice_id: 30
        }, {
          line_item__id: 2,
          line_item__price: 50.0,
          line_item__quantity: 1,
          invoice_id: 31
        }]

        result = @mapper.map_association([@invoice_entity1, @invoice_entity2], :line_items, row_hashes, @session)
        expect(result).to eq({
          result: {
            30 => [@line_item_entity1],
            31 => [@line_item_entity2]
          },
          ids: [1, 2]
        })
      end
    end
  end
end
