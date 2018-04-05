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
end