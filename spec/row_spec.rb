require 'spec_helper'
require 'jet_set/row'

RSpec.describe JetSet::Row do
  describe 'initialize' do
    it 'correctly initializes Row object' do
      today = Date.today
      row_hash = {
        'subscription__id': 101,
        'subscription__active': true,
        'subscription__started_at': today,
        'user__id': 90,
        'user__first_name': 'Alex',
        'plan__id': 1,
        'plan__name': 'business'
      }

      entity_fields = ['id', 'active', 'started_at']
      row = JetSet::Row.new(row_hash, entity_fields, 'subscription')

      expect(row.attributes).to eq([{
        field: 'id',
        value: 101
      }, {
        field: 'active',
        value: true
      }, {
        field: 'started_at',
        value: today
      }])

      expect(row.reference_names).to include('plan', 'user')
    end
  end
end