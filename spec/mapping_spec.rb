require 'spec_helper'
require 'jet_set/mapping'
require 'jet_set/entity_mapping'
require 'samples/domain/plan'

RSpec.describe JetSet::Mapping do
  describe 'entity' do
    it 'registers an entity' do
      mapping = JetSet::Mapping.new do
        entity Plan
      end

      expect(mapping.get(:plan)).to be_a_kind_of(JetSet::EntityMapping)
    end

    context 'when "type" parameter is not a Class' do
      it 'raises MapperError with specific message' do
        expect {
          JetSet::Mapping.new do
            entity 'plan'
          end
        }.to raise_error(JetSet::MapperError, 'Mapping definition of an entity should begin from a type declaration which should be a Class.')
      end
    end

    context 'when the same entity registers twice' do
      it 'raises MapperError with specific message' do
        expect {
          JetSet::Mapping.new do
            entity Plan
            entity Plan
          end
        }.to raise_error(JetSet::MapperError, 'Mapping definition for entity of type Plan is already registered.')
      end
    end
  end

  describe 'get' do
    context 'when entity of requested type is not registered' do
      it 'raises MapperError with specific message' do
        mapping = JetSet::Mapping.new do
        end

        expect{
          mapping.get(:plan)
        }.to raise_error(JetSet::MapperError, 'Entity "plan" is not defined in the mapping.')
      end
    end
  end
end