require 'spec_helper'
require 'jet_set/mapper'
require 'samples/domain/customer'
require 'samples/domain/plan'
require 'samples/domain/subscription'

RSpec.describe 'Mapper' do
  before :each do
    @entity_builder = double(:entity_builder)
    @mapping = double(:mapping)

    entity_mapping = JetSet::EntityMapping.new(Subscription) do
      field :started_at
      field :active
      reference :customer, type: Customer
      reference :plan, type: Plan
    end

    allow(@mapping).to receive(:entity_mappings).and_return({
      subscription: entity_mapping
    })

    @container = double(:container)
    allow(@container).to receive(:register)

    @mapper = JetSet::Mapper.new(@entity_builder, @mapping, @container)
  end

  describe 'map' do
    it 'converts a table row to a type from the mapping' do

    end
  end
end
