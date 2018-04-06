require 'spec_helper'
require 'jet_set/query'
require 'samples/domain/plan'
require 'samples/domain/subscription'
require 'samples/domain/invoice'

RSpec.describe JetSet::Query do
  describe 'returns_single_item?' do
    context 'when returns one item' do
      it 'returns true' do
        query = JetSet::Query.new({
          returns_single_item: true
        })

        expect(query.returns_single_item?).to eql(true)
      end
    end

    context 'when returns more than one item' do
      it 'returns false' do
        query = JetSet::Query.new({
          returns_single_item: false
        })

        expect(query.returns_single_item?).to eql(false)
      end
    end

  end

  describe 'refers_to?' do
    before :each do
      @entity1 = double(:entity1)
      allow(@entity1).to receive(:type).and_return(Plan)

      @entity2 = double(:entity2)
      allow(@entity2).to receive(:type).and_return(Subscription)

      @entities = [@entity1, @entity2]
    end

    context 'when entity of type is present in the query' do
      it 'returns true' do
        query = JetSet::Query.new({
          entities: @entities
        })

        expect(query.refers_to?(Subscription)).to eql(true)
        expect(query.refers_to?(Plan)).to eql(true)
      end
    end

    context 'when entity of type is not present in the query' do
      it 'returns false' do
        query = JetSet::Query.new({
          entities: @entities
        })

        expect(query.refers_to?(Invoice)).to eql(false)
      end
    end

  end
end