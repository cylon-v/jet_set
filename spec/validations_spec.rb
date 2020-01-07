require 'spec_helper'

class ValidatableEntity
  include JetSet::Validations

  validate :title, 'cannot be nil', -> (value){ !value.nil? }

  def initialize(title)
    @title = title
  end
end


RSpec.describe JetSet::Validations do
  describe 'validate!' do
    context 'when there is invalid attribute' do
      it 'raises validation error' do
        obj = ValidatableEntity.new(nil)
        expect {obj.validate!}
          .to raise_error{|error|
            expect(error).to be_a(JetSet::ValidationError)
            expect(error.invalid_items).to include({title: 'cannot be nil'})
          }
      end
    end
  end
end