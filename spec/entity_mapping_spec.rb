require 'spec_helper'
require 'jet_set/collection'
require 'jet_set/mapper_error'
require 'samples/domain/customer'
require 'samples/domain/group'

RSpec.describe JetSet::EntityMapping do
  describe 'initialize' do
    it 'initializes an instance of mapping' do
      entity_mapping = JetSet::EntityMapping.new(Customer)
      expect(entity_mapping.type).to eql(Customer)
      expect(entity_mapping.references).to eql({})
      expect(entity_mapping.collections).to eql({})
      expect(entity_mapping.dependencies).to eql([])
      expect(entity_mapping.fields).to eql(['id'])
    end
  end

  describe 'field' do
    it 'adds a field' do
      entity_mapping = JetSet::EntityMapping.new(Customer) do
        field('name')
      end

      expect(entity_mapping.fields).to include('name')
    end
  end

  describe 'reference' do
    context "when it's weak" do
      it 'adds a reference and dependency' do
        entity_mapping = JetSet::EntityMapping.new(Customer) do
          reference('group', type: Group, weak: true)
        end

        reference = entity_mapping.references['group']
        expect(reference).to be_a_kind_of(JetSet::Reference)
        expect(reference.type).to eql(Group)
        expect(reference.name).to eql('group')

        expect(entity_mapping.dependencies).not_to include(Group)
      end
    end

    context "when it is not weak" do
      it 'adds a reference and dependency' do
        entity_mapping = JetSet::EntityMapping.new(Customer) do
          reference 'group', type: Group
        end

        expect(entity_mapping.dependencies).to include(Group)
      end
    end

    context 'when type is not defined' do
      it 'raises specific error' do
        entity_mapping = JetSet::EntityMapping.new(Customer)
        expect {entity_mapping.reference('group')}.to raise_error(JetSet::MapperError)
      end
    end
  end

  describe 'collection' do
    context 'when type is defined' do
      it 'adds a collection' do
        entity_mapping = JetSet::EntityMapping.new(Customer) do
          collection 'groups', type: Group, using: 'customer_groups'
        end

        collection = entity_mapping.collections['groups']
        expect(collection).to be_a_kind_of(JetSet::Collection)
        expect(collection.type).to eql(Group)
        expect(collection.name).to eql('groups')
        expect(collection.using).to eql('customer_groups')
      end
    end

    context 'when type is not defined' do
      it 'raises specific error' do
        entity_mapping = JetSet::EntityMapping.new(Customer)
        expect {entity_mapping.collection('groups')}.to raise_error(JetSet::MapperError)
      end
    end
  end
end
