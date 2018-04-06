require 'spec_helper'
require 'jet_set/collection'
require 'samples/domain/customer'

RSpec.describe JetSet::EntityBuilder do
  before :all do
    @mapping = double(:mapping)
    @entity_builder = JetSet::EntityBuilder.new(@mapping)
  end

  describe 'create' do
    it 'makes passed object to be trackable' do
      object = double(:object)
      entity = @entity_builder.create(object)
      expect(entity.instance_variable_get('@__attributes')).to eql({})
      expect(entity.instance_variable_get('@__references')).to eql({})
      expect(entity.instance_variable_get('@__collections')).to eql({})
      expect(entity.instance_variable_get('@__mapping')).to eql(@mapping)
      expect(entity.instance_variable_get('@__factory')).to eql(@entity_builder)
      expect(entity.kind_of?(JetSet::Entity)).to eql(true)
      expect(entity.kind_of?(JetSet::Identity)).to eql(true)
    end
  end
end
