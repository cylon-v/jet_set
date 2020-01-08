require 'spec_helper'

class ValidatableEntity
  include JetSet::Validations
  validate_presence :title

  def initialize(attrs)
    @title = attrs[:title]
    @price = attrs[:price]
  end
end

RSpec.describe JetSet::Validations do
  describe 'validate!' do
    context "when there're invalid attributes" do
      it 'raises validation error' do
        obj = ValidatableEntity.new(title: '')
        expect {obj.validate!}
          .to raise_error{|error|
            expect(error).to be_a(JetSet::ValidationError)
            expect(error.invalid_items).to include({title: 'cannot be blank'})
          }
      end
    end
  end
end