require 'spec_helper'
require 'jet_set/mixin/entity'
require 'jet_set/entity_builder'
require 'samples/mapping'
require 'samples/domain/invoice'
require 'samples/domain/subscription'
require 'samples/domain/line_item'

RSpec.describe 'Entity' do
  before :each do
    @mapping = Mapping.load_mapping
    @entity_builder = JetSet::EntityBuilder.new(@mapping)
    @entity = @entity_builder.create(Invoice.new)
  end

  describe 'load_attributes!' do
    it 'sets instance variables and adds the attributes to the collection' do
      today = Date.today

      @entity.load_attributes!([{
        field: 'amount',
        value: 100.0,
      }, {
        field: 'created_at',
        value: today
      }])

      expect(@entity.amount).to eql(100.0)
      expect(@entity.created_at).to eql(today)

      attributes = @entity.instance_variable_get('@__attributes')
      expect(attributes['@amount'].name).to eql('@amount')
      expect(attributes['@amount'].value).to eql(100.0)
      expect(attributes['@created_at'].name).to eql('@created_at')
      expect(attributes['@created_at'].value).to eql(today)
    end
  end

  describe 'set_reference!' do
    it 'adds a reference to another entity' do
      reference_entity = @entity_builder.create(Subscription.new)
      @entity.set_reference!('subscription', reference_entity)

      references = @entity.instance_variable_get('@__references')
      expect(references['subscription']).to eql(reference_entity)
      expect(@entity.subscription).to eql(reference_entity)
    end
  end

  describe 'set_collection!' do
    it 'sets a collection of another entities' do
      @line_item_entity1 = @entity_builder.create(LineItem.new)
      @line_item_entity1.instance_variable_set('@id', 1)

      @line_item_entity2 = @entity_builder.create(LineItem.new)
      @line_item_entity2.instance_variable_set('@id', 2)
      @entity.set_collection!('line_items', [@line_item_entity1, @line_item_entity2])

      references = @entity.instance_variable_get('@__collections')
      expect(references['line_items']).to include(1, 2)
      expect(@entity.line_items).to include(@line_item_entity1, @line_item_entity2)
    end
  end

  describe 'new?' do
    context 'when id is nil' do
      it 'returns true' do
        @entity.instance_variable_set('@id', nil)
        expect(@entity.new?).to eql(true)
      end
    end

    context 'when id is not nil' do
      it 'returns false' do
        @entity.instance_variable_set('@id', 1)
        expect(@entity.new?).to eql(false)
      end
    end
  end

  describe 'dirty?' do
    context 'when it\'s new' do
      it 'returns true' do
        allow(@entity).to receive(:new?).and_return(true)
        expect(@entity.dirty?).to eql(true)
      end
    end

    context 'when it\'s not new'  do
      context 'and in default state' do
        before :each do
          allow(@entity).to receive(:new?).and_return(false)
        end
        it 'returns false' do
          expect(@entity.dirty?).to eql(false)
        end
      end

      context 'and state is changed' do
        before :each do
          allow(@entity).to receive(:new?).and_return(false)
        end

        context 'when it has a changed attribute' do
          it 'returns true' do
            attribute = double(:attribute)
            allow(attribute).to receive(:name).and_return('@amount')
            allow(attribute).to receive(:changed?).and_return(true)

            @entity.instance_variable_set('@__attributes', amount: attribute)

            expect(@entity.dirty?).to eql(true)
          end
        end

        context 'when it has a changed collection' do
          it 'returns true' do
            @line_item_entity = @entity_builder.create(LineItem.new)
            @line_item_entity.instance_variable_set('@id', 1)

            @entity.instance_variable_set('@__collections', {'line_items': []})
            @entity.instance_variable_set('@line_items', [@line_item_entity])

            expect(@entity.dirty?).to eql(true)
          end
        end

        context 'when reference is changed' do
          it 'returns true' do
            @subscription_entity = @entity_builder.create(Subscription.new)
            @subscription_entity.instance_variable_set('@id', 1)

            @another_subscription_entity = @entity_builder.create(Subscription.new)
            @another_subscription_entity.instance_variable_set('@id', 2)

            @entity.instance_variable_set('@__references', {'subscription': @subscription_entity})
            @entity.instance_variable_set('@subscription', @another_subscription_entity)

            expect(@entity.dirty?).to eql(true)
          end
        end
      end
    end
  end

  describe 'dirty_attributes' do
    it 'returns changed attributes' do
      attribute = double(:attribute)
      allow(attribute).to receive(:name).and_return('@created_at')
      allow(attribute).to receive(:changed?).and_return(false)

      changed_attribute = double(:changed_attribute)
      allow(changed_attribute).to receive(:name).and_return('@amount')
      allow(changed_attribute).to receive(:changed?).and_return(true)

      @entity.instance_variable_set('@__attributes', '@created_at': attribute, '@amount': changed_attribute)

      expect(@entity.dirty_attributes).to include(changed_attribute)
      expect(@entity.dirty_attributes).not_to include(attribute)
    end
  end

  describe 'flush' do
    before :each do
      @connection = double(:connection)

      @invoices_table = double(:invoices_table)
      allow(@connection).to receive(:[]).with(:invoices).and_return(@invoices_table)

      @subscriptions_table = double(:subscriptions_table)
      allow(@connection).to receive(:[]).with(:subscriptions).and_return(@subscriptions_table)
    end

    context 'when entity responds to "validate" method' do
      before :each do
        allow(@entity).to receive(:validate)
        allow(@invoices_table).to receive(:insert)
      end

      it 'calls "validate" method' do
        expect(@entity).to receive(:validate)
        @entity.flush(@connection)
      end
    end

    context 'when it is new' do
      it 'inserts new record into the table' do
        today = Date.today
        @subscription = Subscription.new({active: true})
        @subscription.instance_variable_set('@id', 'some-subscription-id')

        @entity.instance_variable_set('@subscription', @subscription)
        @entity.instance_variable_set('@created_at', today)
        @entity.instance_variable_set('@amount', 100.0)
        expect(@invoices_table).to receive(:insert).with(['amount', 'created_at', 'subscription_id'], [100.0, today, 'some-subscription-id']).ordered
        @entity.flush(@connection)
      end

      context 'and it contains weak reference' do
        it 'does not save it' do
          @subscription = Subscription.new({active: true})
          @entity.instance_variable_set('@subscription', @subscription)

          expect(@subscriptions_table).not_to receive(:insert)
          expect(@invoices_table).to receive(:insert)
          @entity.flush(@connection)
        end
      end

      context 'and it contains strong reference' do
        before :each do
          @invoice_history_table = double(:invoice_history_table)
          allow(@connection).to receive(:[]).with(:invoice_histories).and_return(@invoice_history_table)
        end

        it 'saves it' do
          history = InvoiceHistory.new
          @entity.instance_variable_set('@history', history)

          expect(@invoice_history_table).to receive(:insert)
          expect(@invoices_table).to receive(:insert)
          @entity.flush(@connection)
        end
      end
    end

    context 'when it is dirty' do
      it 'inserts the record in the table' do
        attribute = double(:attribute)
        allow(attribute).to receive(:name).and_return('@amount')
        allow(attribute).to receive(:changed?).and_return(true)
        @entity.instance_variable_set('@__attributes', {'@amount': attribute})
        @entity.instance_variable_set('@id', 1)
        @entity.instance_variable_set('@amount', 200.0)

        expect(@invoices_table).to receive(:where).with(id: 1).and_return(@invoices_table)
        expect(@invoices_table).to receive(:update).with('amount' => 200.0)
        @entity.flush(@connection)
      end
    end

    context 'when a collection contains new items' do
      context 'and it is one-to-many association' do
        it 'inserts the items into their table' do
          @line_items_table = double(:line_items_table)
          allow(@connection).to receive(:[]).with(:line_items).and_return(@line_items_table)

          @entity.instance_variable_set('@id', 1)
          @entity.line_items << LineItem.new(price: 100.0, quantity: 1)
          @entity.line_items << LineItem.new(price: 50.0, quantity: 2)

          expect(@line_items_table).to receive(:insert).with(['price', 'quantity'], [100.0, 1])
          expect(@line_items_table).to receive(:insert).with(['price', 'quantity'], [50.0, 2])
          @entity.flush(@connection)
        end
      end

      context 'and it is many-to-many association' do
        it 'inserts the items into many-to-many relation table' do
          @customer = @entity_builder.create(Customer.new)
          @customers_table = double(:customers_table)
          allow(@connection).to receive(:[]).with(:customers).and_return(@customers_table)

          @groups_table = double(:groups_table)
          allow(@connection).to receive(:[]).with(:groups).and_return(@groups_table)

          @association_table = double(:association_table)
          allow(@connection).to receive(:[]).with(:customer_groups).and_return(@association_table)


          @customer.instance_variable_set('@id', 'customer_id')
          @customer.groups << Group.new(name: 'Users')
          @customer.groups << Group.new(name: 'Admins')

          expect(@groups_table).to receive(:insert).with(['name'], ['Users']).and_return('group-id-1')
          expect(@groups_table).to receive(:insert).with(['name'], ['Admins']).and_return('group-id-2')

          expect(@association_table).to receive(:insert).with(['customer_id', 'group_id'], ['customer_id', 'group-id-1'])
          expect(@association_table).to receive(:insert).with(['customer_id', 'group_id'], ['customer_id', 'group-id-2'])

          @customer.flush(@connection)
        end
      end
    end

    context 'when a collection has a removed items' do
      context 'and it is one-to-many association' do
        it 'removes the item from its table' do
          @entity.instance_variable_set('@id', 1)

          @line_items_table = double(:line_items_table)
          allow(@connection).to receive(:[]).with(:line_items).and_return(@line_items_table)

          line_item1 = @entity_builder.create(LineItem.new(price: 100.0, quantity: 1))
          line_item1.instance_variable_set('@id', 'line-item-1')

          line_item2 = @entity_builder.create(LineItem.new(price: 50.0, quantity: 2))
          line_item2.instance_variable_set('@id', 'line-item-2')

          initial_state = @entity.instance_variable_get('@__collections')
          initial_state[:line_items] = [line_item1.id, line_item2.id]
          @entity.instance_variable_set('@line_items', [line_item1])

          expect(@line_items_table).to receive(:where).with(id: ['line-item-2']).and_return(@line_items_table).ordered
          expect(@line_items_table).to receive(:delete).ordered
          @entity.flush(@connection)
        end
      end

      context 'and it is many-to-many association' do
        it 'removes the row from association table' do
          @entity.instance_variable_set('@id', 1)

          customer = @entity_builder.create(Customer.new)
          customer.instance_variable_set('@id', 'customer-1')

          customers_table = double(:customers_table)
          allow(@connection).to receive(:[]).with(:customers).and_return(customers_table)

          groups_table = double(:groups_table)
          allow(@connection).to receive(:[]).with(:groups).and_return(groups_table)

          association_table = double(:association_table)
          allow(@connection).to receive(:[]).with(:customer_groups).and_return(association_table)

          group1 = @entity_builder.create(Group.new(name: 'Users'))
          group1.instance_variable_set('@id', 'group-1')

          group2 = @entity_builder.create(Group.new(name: 'Admins'))
          group2.instance_variable_set('@id', 'group-2')

          initial_state = customer.instance_variable_get('@__collections')
          initial_state[:groups] = [group1.id, group2.id]
          customer.instance_variable_set('@groups', [])

          expect(association_table).to receive(:where).with('customer_id' => 'customer-1', 'group_id' => 'group-1')
                                         .and_return(association_table).ordered
          expect(association_table).to receive(:delete).ordered

          expect(association_table).to receive(:where).with('customer_id' => 'customer-1', 'group_id' => 'group-2')
                                         .and_return(association_table).ordered
          expect(association_table).to receive(:delete).ordered

          customer.flush(@connection)
        end
      end
    end
  end
end