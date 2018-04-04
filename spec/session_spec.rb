require 'spec_helper'
require 'jet_set/session'
require 'jet_set/mapper_error'
require 'samples/domain/customer'
require 'samples/domain/plan'

RSpec.describe 'Session' do
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

  end

  describe 'finalize' do

  end
end