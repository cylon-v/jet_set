require 'spec_helper'

class ValidatableEntity
  include JetSet::Validations
  validate :title, {
    :type => :string,
    presence: true,
    message: 'should start with "Title"',
    custom: -> (value) {value.start_with?('Title')}
  }

  validate :price, :type => :numeric
  validate :done, :type => :boolean

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
        obj = ValidatableEntity.new(title: 'Title: Cool name', price: 10.0, done: true)
        expect {obj.validate!}.not_to raise_error
      end
    end
  end

  describe 'do_not_validate' do
    it 'skips further validation of the field' do
      obj = ValidatableEntity.new(title: '', price: 12.0, done: true)
      obj.do_not_validate(:title)
      expect {obj.validate!}.not_to raise_error
    end
  end

  describe 'validate type' do
    context 'when type is incorrect' do
      it 'raises validation definition error' do
        expect {ValidatableEntity.validate(:title, type: String)}
          .to raise_error JetSet::ValidationDefinitionError, 'the type should be :numeric, :string or :boolean'
      end
    end
  end

  describe 'validate' do
    context 'when syntax is incorrect' do
      it 'raises validation definition error' do
        expect {ValidatableEntity.validate(:title, 123)}
          .to raise_error JetSet::ValidationDefinitionError, 'Validation definition of attribute title is incorrect.'
      end
    end
  end
end