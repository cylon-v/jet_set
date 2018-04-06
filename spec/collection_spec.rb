require 'spec_helper'
require 'jet_set/collection'
require 'samples/domain/customer'

RSpec.describe JetSet::Collection do
  describe 'initialize' do
    it 'properly initializes the collection' do
      collection = JetSet::Collection.new('customers', Customer, 'group_customers')
      expect(collection.name).to eql('customers')
      expect(collection.type).to eql(Customer)
      expect(collection.using).to eql('group_customers')
    end
  end
end
