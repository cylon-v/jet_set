require 'spec_helper'
require 'jet_set/mixin/entity'
require 'jet_set/session'
require 'jet_set/mapper_error'
require 'samples/domain/customer'
require 'samples/domain/plan'

RSpec.describe JetSet::Session do
  before :each do
    @connection = double(:connection)
    @mapper = double(:mapper)
    @query_parser = double(:query_parser)
    @entity_builder = double(:entity_builder)
    @dependency_graph = double(:dependency_graph)

    @session = JetSet::Session.new(@connection, @mapper, @query_parser, @entity_builder, @dependency_graph)
  end

  describe 'fetch' do
    context 'when "type" parameter is not a Class' do
      it 'raises MapperError with specific message' do
        expect {
          @session.fetch(:plan, '...')
        }.to raise_error(JetSet::MapperError, 'Parameter "type" should be a Class.')
      end
    end

    context 'when the type entity is not present in the query' do
      before :each do
        query = double(:query)
        allow(query).to receive(:refers_to?).with(Plan).and_return(false)
        allow(@query_parser).to receive(:parse).and_return(query)
      end

      it 'raises MapperError with specific message' do
        expect{
          @session.fetch(Plan, '...')
        }.to raise_error(JetSet::MapperError, 'The query doesn\'t contain "AS ENTITY plan" statement.')
      end
    end

    context 'when the type entity is present in the query' do
      before :each do
        @query = double(:query)
        allow(@query).to receive(:refers_to?).with(Plan).and_return(true)
        allow(@query).to receive(:sql).and_return('...')
        allow(@query_parser).to receive(:parse).and_return(@query)
      end

      context 'when the query returns 0 items' do
        before :each do
          allow(@connection).to receive(:fetch).and_return([])
        end

        it 'returns nil' do
          result = @session.fetch(Plan, '...')
          expect(result).to be_nil
        end
      end

      context 'when the query returns 1 item' do
        before :each do
          @entity = double(:entity)
          allow(@mapper).to receive(:map).and_return(@entity)

          rows = [{
            'plan__id': 1,
            'plan__name': 'business'
          }]
          allow(@connection).to receive(:fetch).and_return(rows)
        end

        context 'when the query should return 1 item' do
          before :each do
            allow(@query).to receive(:returns_single_item?).and_return(true)
          end

          it 'returns single item' do
            result = @session.fetch(Plan, '...')
            expect(result).to eq(@entity)
          end
        end

        context 'when the query can return more than 1 item' do
          before :each do
            allow(@query).to receive(:returns_single_item?).and_return(false)
          end

          it 'returns an array with 1 item' do
            result = @session.fetch(Plan, '...')
            expect(result).to eq([@entity])
          end
        end
      end

      context 'when the query returns more than 1 item' do
        before :each do
          row1 = {
            'plan__id': 1,
            'plan__name': 'business'
          }

          row2 = {
            'plan__id': 2,
            'plan__name': 'premium'
          }
          rows = [row1, row2]
          allow(@connection).to receive(:fetch).and_return(rows)

          @entity1 = double(:entity1)
          allow(@mapper).to receive(:map).with(Plan, row1, @session).and_return(@entity1)

          @entity2 = double(:entity2)
          allow(@mapper).to receive(:map).with(Plan, row2, @session).and_return(@entity2)
        end

        context 'but we expect only 1 item' do
          before :each do
            allow(@query).to receive(:returns_single_item?).and_return(true)
          end

          it 'raises MapperError with specific message' do
            expect{
              @session.fetch(Plan, '...')
            }.to raise_error(JetSet::MapperError, 'A single row was expected to map but the query returned 2 rows.')
          end
        end

        context 'and we expect more than 1 item' do
          before :each do
            allow(@query).to receive(:returns_single_item?).and_return(false)
          end

          it 'returns an array with multiple items' do
            result = @session.fetch(Plan, '...')
            expect(result).to include(@entity1, @entity2)
          end
        end
      end

      context 'when a block is given' do
        it 'executes the block' do
          allow(@connection).to receive(:fetch).and_return([])

          block_executed = false
          @session.fetch(Plan, '...') do
            block_executed = true
          end

          expect(block_executed).to eql(true)
        end
      end
    end
  end

  describe 'preload' do
    it 'executes specific steps' do
      query_expression = 'some query'
      sql_expression = 'some sql'
      target = [Customer.new]
      params = {
        customer_id: 1
      }
      relation = :groups

      query = double(:query)
      allow(query).to receive(:sql).and_return(sql_expression)

      expect(@query_parser).to receive(:parse).with(query_expression).and_return(query)

      rows = []
      expect(@connection).to receive(:fetch).with(sql_expression, params).and_return(rows)

      mapper_result = {
        result: [],
        ids: []
      }
      expect(@mapper).to receive(:map_association).with(target, relation, rows, @session).and_return(mapper_result)

      z = self
      @session.preload(target, relation, query_expression, params) do |groups, ids|
        z.expect(groups).to z.eql(mapper_result[:result])
        z.expect(ids).to z.eql(mapper_result[:ids])
      end
    end
  end

  describe 'attach' do
    before :each do
      @entity = double(:entity)
      allow(@entity).to receive(:kind_of?).with(JetSet::Entity).and_return(true)
    end

    context 'when object is an entity' do
      it 'just adds it to the session' do
        expect(@entity_builder).to_not receive(:create).with(@entity)

        @session.attach(@entity)
        expect(@session.instance_variable_get('@objects')).to include(@entity)
      end
    end

    context 'when entity responds to "validate" method' do
      before :each do
        allow(@entity).to receive(:validate!)
      end

      it 'calls "validate" method' do
        expect(@entity).to receive(:validate!)
        @session.attach(@entity)
      end
    end

    context 'when object is a pure Ruby object' do
      it 'converts it to an entity and then adds to the session' do
        plan = Plan.new
        expect(@entity_builder).to receive(:create).with(plan).and_return(@entity)

        @session.attach(plan)
        expect(@session.instance_variable_get('@objects')).to include(@entity)
      end
    end

    context 'when the parameter is an array' do
      it 'successfully add all objects to the session' do
        plan1 = Plan.new
        plan1_entity = double(:plan1_entity)

        plan2 = Plan.new
        plan2_entity = double(:plan2_entity)

        customer1 = Customer.new
        customer1_entity = double(:customer1_entity)

        customer2 = Customer.new
        customer2_entity = double(:customer2_entity)

        expect(@entity_builder).to receive(:create).with(plan1).and_return(plan1_entity)
        expect(@entity_builder).to receive(:create).with(plan2).and_return(plan2_entity)
        expect(@entity_builder).to receive(:create).with(customer1).and_return(customer1_entity)
        expect(@entity_builder).to receive(:create).with(customer2).and_return(customer2_entity)

        @session.attach(plan1, plan2, [customer1, customer2], @entity)
        expect(@session.instance_variable_get('@objects'))
          .to include(@entity, plan1_entity, plan2_entity, customer1_entity, customer2_entity)
      end
    end
  end

  describe 'finalize' do
    before :each do
      @clean_object = double(:clean_object)
      allow(@clean_object).to receive(:dirty?).and_return(false)
    end

    context 'when there are dirty objects in the session' do
      it 'flushes dirty objects using the connection transaction according to order of their dependencies' do
        dirty_object1 = double(:dirty_object1)
        allow(dirty_object1).to receive(:dirty?).and_return(true)

        dirty_object2 = double(:dirty_object2)
        allow(dirty_object2).to receive(:dirty?).and_return(true)

        @session.instance_variable_set('@objects', [@clean_object, dirty_object1, dirty_object2])

        expect(@dependency_graph).to receive(:order).with([dirty_object1, dirty_object2])
                                       .and_return([dirty_object2, dirty_object1])
        expect(@connection).to receive(:transaction) do |&block|
          instance_exec(&block)
        end

        expect(@clean_object).to_not receive(:flush)
        expect(dirty_object2).to receive(:flush).ordered
        expect(dirty_object1).to receive(:flush).ordered

        @session.finalize
      end
    end

    context 'when there are dirty objects in the session' do
      it 'flushes dirty objects using the connection transaction according to order of their dependencies' do
        @session.instance_variable_set('@objects', [@clean_object])

        expect(@dependency_graph).to receive(:order).with([]).and_return([])
        expect(@connection).not_to receive(:transaction)
        expect(@clean_object).not_to receive(:flush).ordered

        @session.finalize
      end
    end
  end
end