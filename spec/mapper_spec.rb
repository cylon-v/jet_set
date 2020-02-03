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

RSpec.describe JetSet::Mapper do
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
      @group = Group.new(name: 'My Group')
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

      allow(@container).to receive(:resolve).with(:jet_set__subscription, hash_including({id: 1, active: false})).and_return(@subscription)
      allow(@container).to receive(:resolve).with(:jet_set__plan, hash_including({id: 2, price: 100.0})).and_return(@plan)
      allow(@container).to receive(:resolve).with(:jet_set__customer, hash_including({id: 3, first_name: 'Alex'})).and_return(@customer)

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

    it 'does not map nil associations' do
      row_hash = {
        subscription__id: 1,
        subscription__active: false,
        plan__id: nil
      }

      allow(@container).to receive(:resolve).with(:jet_set__subscription, {id: 1, active: false}).and_return(@subscription)

      @subscription_entity = double(:subscription_entity)
      @plan_entity = double(:plan_entity)

      expect(@entity_builder).to receive(:create).with(@subscription).and_return(@subscription_entity)
      expect(@entity_builder).not_to receive(:create).with(@plan)

      expect(@subscription_entity).to receive(:load_attributes!)
      expect(@subscription_entity).not_to receive(:set_reference!).with('plan', @plan_entity)

      expect(@session).to receive(:attach).with(@subscription_entity)
      expect(@session).not_to receive(:attach).with(@plan_entity)
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

        expect(@container).to receive(:resolve)
                                .with(:jet_set__line_item, hash_including({id: 1, price: 100.0, quantity: 1}))
                                .and_return(@line_item1)
        expect(@container).to receive(:resolve)
                                .with(:jet_set__line_item, hash_including({id: 2, price: 50.0, quantity: 1}))
                                .and_return(@line_item2)

        expect(@container).to receive(:resolve).with(:jet_set__invoice, {id: 30}).and_return(@invoice).twice

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
      context "and it's one-to-many association"  do
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

          allow(@container).to receive(:resolve).with(:jet_set__invoice).and_return(@invoice1)
          allow(@container).to receive(:resolve).with(:jet_set__invoice).and_return(@invoice2)
        end

        context 'when reverse id is not defined' do
          it 'raises MapperError with specific message' do
            expect(@container).to receive(:resolve).with(:jet_set__line_item, {id: 1, price: 100.0, quantity: 1}).and_return(@line_item1)

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
          expect(@container).to receive(:resolve).with(:jet_set__line_item, {id: 1, price: 100.0, quantity: 1}).and_return(@line_item1)
          expect(@container).to receive(:resolve).with(:jet_set__line_item, {id: 2, price: 50.0, quantity: 1}).and_return(@line_item2,)

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

      context "and it's many-to-many association"  do
        before :each do
          @customer1 = Customer.new
          @customer2 = Customer.new
          @customer_entity1 = double(:customer_entity1)
          @customer_entity2 = double(:customer_entity2)
          allow(@customer_entity1).to receive(:class).and_return(Customer)
          allow(@customer_entity2).to receive(:class).and_return(Customer)
          allow(@customer_entity1).to receive(:id).and_return(1)
          allow(@customer_entity2).to receive(:id).and_return(2)

          @group1 = Group.new(name: 'Group 1')
          @group2 = Group.new(name: 'Group 2')
          @group_entity1 = double(:group_entity1)
          @group_entity2 = double(:group_entity2)
          allow(@group_entity1).to receive(:id).and_return(21)
          allow(@group_entity2).to receive(:id).and_return(22)

          allow(@container).to receive(:resolve).with(:jet_set__customer).and_return(@customer1)
          allow(@container).to receive(:resolve).with(:jet_set__customer).and_return(@customer2)
        end

        it 'adds a complex association to the array of targets' do
          expect(@container).to receive(:resolve).with(:jet_set__group, {id: 21}).and_return(@group1)
          expect(@container).to receive(:resolve).with(:jet_set__group, {id: 22}).and_return(@group2)

          expect(@entity_builder).to receive(:create).with(@group1).and_return(@group_entity1)
          expect(@entity_builder).to receive(:create).with(@group2).and_return(@group_entity2)

          expect(@group_entity1).to receive(:load_attributes!)
          expect(@group_entity2).to receive(:load_attributes!)

          expect(@session).to receive(:attach).with(@group_entity1)
          expect(@session).to receive(:attach).with(@group_entity2)

          expect(@customer_entity1).to receive(:set_collection!).with(:groups, [@group_entity1])
          expect(@customer_entity2).to receive(:set_collection!).with(:groups, [@group_entity2])
          expect(@group_entity1).to receive(:set_collection!).with(:customers, [@customer_entity1])
          expect(@group_entity2).to receive(:set_collection!).with(:customers, [@customer_entity2])

          row_hashes = [{
            group__id: 21,
            name: 'Super Users',
            customer_id: 1
          }, {
            group__id: 22,
            name: 'Power Users',
            customer_id: 2
          }]

          result = @mapper.map_association([@customer_entity1, @customer_entity2], :groups, row_hashes, @session)
          expect(result).to eq({
            result: {
              1 => [@group_entity1],
              2 => [@group_entity2]
            },
            ids: [21, 22]
          })
        end
      end
    end

  end
end
