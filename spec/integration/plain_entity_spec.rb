require 'spec_helper'
require 'sequel'
require 'logger'
require 'samples/mapping'
require 'samples/domain/plan'
require 'jet_set/validation_error'

RSpec.describe 'Plain entity', integration: true do
  Sequel.extension :migration

  before :all do
    @connection = Sequel.connect('sqlite:/')
    # @connection.logger = Logger.new($stdout)
    Sequel::Migrator.run(@connection, 'spec/integration/migrations', :use_transactions => false)

    @container = Hypo::Container.new
    JetSet::init(Mapping.load_mapping, @container)
    @session = JetSet::open_session(@connection)
  end


  describe 'session attach and finalize' do
    it 'successfully saves single plain object' do
      plan = Plan.new(name: 'business', price: 25.0)
      @session.attach(plan)
      @session.finalize

      result = @connection[:plans].all[0]
      expect(result[:name]).to eql('business')
    end
  end

  describe 'create/read' do
    it 'successfully returns plain object' do
      plan_to_save = Plan.new(name: 'my_plan', price: 25.0)
      @session.attach(plan_to_save)
      @session.finalize

      query = <<~SQL
        SELECT
          p.* AS ENTITY plan
        FROM plans p
        WHERE p.name = :plan_name
        LIMIT 1
      SQL

      loaded_plan = @session.fetch(Plan, query, plan_name: 'my_plan')

      expect(loaded_plan.name).to eql('my_plan')
    end
  end

  describe 'updating' do
    it 'successfully updates single plain object' do
      plan_to_save = Plan.new(name: 'my_plan', price: 25.0)
      @session.attach(plan_to_save)
      @session.finalize

      query = <<~SQL
        SELECT
          p.* AS ENTITY plan
        FROM plans p
        WHERE p.name = :plan_name
        LIMIT 1
      SQL

      loaded_plan = @session.fetch(Plan, query, plan_name: 'my_plan')
      loaded_plan.update(name: 'no_plan')
      @session.finalize

      updated_plan = @session.fetch(Plan, query, plan_name: 'no_plan')

      expect(updated_plan.name).to eql('no_plan')
    end
  end

  describe 'validation', :focus do
    context 'of new instance' do
      context 'when name is invalid' do
        it 'raises validation error' do
          plan_to_save = Plan.new(price: 25.0)
          @session.attach(plan_to_save)
          expect { @session.finalize }.to raise_error(JetSet::ValidationError)
        end
      end
    end

    context 'of updated instance' do
      context 'when name is invalid' do
        it 'raises validation error' do
          plan_to_save = Plan.new(name: 'my_plan', price: 25.0)
          @session.attach(plan_to_save)
          @session.finalize

          query = <<~SQL
            SELECT
              p.* AS ENTITY plan
            FROM plans p
            WHERE p.name = :plan_name
            LIMIT 1
          SQL

          loaded_plan = @session.fetch(Plan, query, plan_name: 'my_plan')
          loaded_plan.update(name: nil)
          expect { @session.finalize }.to raise_error(JetSet::ValidationError)
        end
      end
    end
  end
end