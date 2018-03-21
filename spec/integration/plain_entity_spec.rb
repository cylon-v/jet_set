require 'spec_helper'
require 'sequel'
require 'logger'
require 'samples/mapping'
require 'samples/domain/plan'

RSpec.describe 'Plain entity' do
  Sequel.extension :migration

  before :all do
    @connection = Sequel.connect('sqlite:/')
    @connection.logger = Logger.new($stdout)
    Sequel::Migrator.run(@connection, 'spec/samples/migrations', :use_transactions => false)

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
      SQL

      loaded_plan = @session.execute(query, plan_name: 'my_plan') do |row|
        map(Plan, row)
      end

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

      loaded_plan = @session.execute(query, plan_name: 'my_plan') do |row|
        map(Plan, row)
      end

      loaded_plan.update(name: 'no_plan')
      @session.finalize

      updated_plan = @session.execute(query, plan_name: 'no_plan') do |row|
        map(Plan, row)
      end

      expect(updated_plan.name).to eql('no_plan')
    end
  end
end