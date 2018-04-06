require 'spec_helper'
require 'jet_set/attribute'

RSpec.describe JetSet::Attribute do
  describe 'changed' do
    context "when it is not an array" do
      before :all do
        @attribute = JetSet::Attribute.new('my_attribute', 'my value')
      end

      context 'and value is equal to original' do
        it 'returns false' do
          expect(@attribute.changed?('my value')).to eql(false)
        end
      end

      context 'and value is not equal to original' do
        it 'returns false' do
          expect(@attribute.changed?('my value was changed')).to eql(true)
        end
      end
    end

    context "when it's an array of entities" do
      before :each do
        @entity1 = double(:entity1)
        allow(@entity1).to receive(:id).and_return(1)
        @entity2 = double(:entity2)
        allow(@entity2).to receive(:id).and_return(2)

        @attribute = JetSet::Attribute.new('my_attribute', [@entity1])
      end

      context 'and it is not equal to origin' do
        context 'in case when an item added' do
          it 'returns true' do
            expect(@attribute.changed?([@entity1, @entity2])).to eql(true)
          end
        end

        context 'in case when an item replaced' do
          it 'returns true' do
            expect(@attribute.changed?([@entity1, @entity2])).to eql(true)
          end
        end

        context 'in case when an item removed' do
          it 'returns true' do
            expect(@attribute.changed?([])).to eql(true)
          end
        end

        context 'in case when an untracked item added' do
          it 'returns true' do
            untracked_entity = double(:untracked_entity)
            expect(@attribute.changed?([@entity1, untracked_entity])).to eql(true)
          end
        end
      end
    end
  end
end