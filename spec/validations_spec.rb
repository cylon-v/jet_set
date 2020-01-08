require 'spec_helper'

class ValidatableEntity
  include JetSet::Validations
  validate_type :title, :string
  validate_presence :title

  validate_type :price, :numeric
  validate_type :done, :boolean

  def initialize(attrs)
    @title = attrs[:title]
    @price = attrs[:price]
    @done = attrs[:done]
  end
end

RSpec.describe JetSet::Validations do
  describe 'validate!' do
    context 'when all attributes are invalid' do
      it 'raises validation error' do
        obj = ValidatableEntity.new(title: '', price: 'a string', done: 1)
        expect {obj.validate!}
          .to raise_error{|error|
            expect(error).to be_a(JetSet::ValidationError)
            expect(error.invalid_items)
              .to include({title: 'cannot be blank'}, {price: 'should be numeric'}, {done: 'should be boolean'})
          }
      end
    end

    context 'when all attributes are valid' do
      it 'doesn\'t raise validation error' do
        obj = ValidatableEntity.new(title: 'Cool name', price: 10.0, done: true)
        expect {obj.validate!}
          .not_to raise_error
      end
    end
  end

  describe 'validate_type' do
    context 'when type is incorrect' do
      it 'raises validation definition error' do
        expect {ValidatableEntity.validate_type(:title, String)}
          .to raise_error JetSet::ValidationDefinitionError, 'the type should be :numeric, :string or :boolean'
      end
    end
  end
end